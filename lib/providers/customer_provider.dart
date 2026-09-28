import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/services/customer_service.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Provider for managing customer list and stats in Admin panel
class CustomerProvider extends ChangeNotifier {
  List<UserModel> _customers = [];
  final Map<String, Map<String, dynamic>> _customerStats = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  bool? _activeFilter;
  StreamSubscription<List<UserModel>>? _subscription;

  List<UserModel> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool? get activeFilter => _activeFilter;

  CustomerProvider() {
    init();
  }

  void init() {
    watchCustomers();
  }

  String? _currentBranchId;
  String? get currentBranchId => _currentBranchId;

  /// Watch real-time customer data
  void watchCustomers({String? search, bool? isActive, String? branchId}) {
    if (branchId != null) _currentBranchId = branchId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = CustomerService.watchCustomers(
      search: search ?? _searchQuery,
      isActive: isActive ?? _activeFilter,
      branchId: _currentBranchId,
    ).listen(
      (data) {
        _customers = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load customers: $e';
        AppLogger.error('CustomerProvider watch error: $e', tag: 'CustomerProvider');
        notifyListeners();
      },
    );
  }

  /// Filter search query
  void setSearch(String query) {
    _searchQuery = query;
    watchCustomers(search: query, isActive: _activeFilter, branchId: _currentBranchId);
  }

  /// Filter by active/inactive
  void setActiveFilter(bool? isActive) {
    _activeFilter = isActive;
    watchCustomers(search: _searchQuery, isActive: isActive, branchId: _currentBranchId);
  }

  /// Toggle status
  Future<bool> toggleCustomerStatus(String userId, bool currentStatus) async {
    try {
      await CustomerService.toggleCustomerStatus(userId, currentStatus);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update customer status: $e';
      AppLogger.error('Toggle customer status error: $e', tag: 'CustomerProvider');
      notifyListeners();
      return false;
    }
  }

  /// Load order stats for customer
  Future<Map<String, dynamic>> getCustomerStats(String customerId) async {
    if (_customerStats.containsKey(customerId)) {
      return _customerStats[customerId]!;
    }
    final stats = await CustomerService.getCustomerStats(customerId);
    _customerStats[customerId] = stats;
    notifyListeners();
    return stats;
  }

  Map<String, dynamic>? statsFor(String customerId) => _customerStats[customerId];

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
