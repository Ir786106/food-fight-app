import 'package:flutter/material.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/services/customer_service.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/utils/safe_change_notifier.dart';

/// Provider for managing customer list and stats in Admin panel
class CustomerProvider extends ChangeNotifier with SafeChangeNotifier {
  List<UserModel> _customers = [];
  final Map<String, Map<String, dynamic>> _customerStats = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  bool? _activeFilter;
  int _loadGeneration = 0;

  List<UserModel> get customers {
    final query = _searchQuery.trim().toLowerCase();
    return _customers.where((customer) {
      if (_activeFilter != null && customer.isActive != _activeFilter) return false;
      return customer.name.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query);
    }).toList(growable: false);
  }
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool? get activeFilter => _activeFilter;

  CustomerProvider();

  void init() {
    loadCustomers();
  }

  String? _currentBranchId;
  String? get currentBranchId => _currentBranchId;

  Future<void> loadCustomers({String? branchId, bool scopeChanged = false}) async {
    if (scopeChanged) {
      _currentBranchId = branchId;
      _customers = [];
      _customerStats.clear();
    }
    final generation = ++_loadGeneration;
    _isLoading = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    try {
      final customers = await CustomerService.getCustomers();
      if (generation == _loadGeneration) _customers = customers;
    } catch (error) {
      if (generation != _loadGeneration) return;
      _customers = [];
      _errorMessage = 'Unable to load customers. Please try again.';
      AppLogger.error('Customer directory load failed: $error', tag: 'CustomerProvider');
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Filter search query
  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Filter by active/inactive
  void setActiveFilter(bool? isActive) {
    _activeFilter = isActive;
    notifyListeners();
  }

  /// Toggle status
  Future<bool> toggleCustomerStatus(String userId, bool currentStatus) async {
    try {
      await CustomerService.toggleCustomerStatus(userId, currentStatus);
      await loadCustomers();
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
    final stats = await CustomerService.getCustomerStats(customerId, branchId: _currentBranchId);
    _customerStats[customerId] = stats;
    notifyListeners();
    return stats;
  }

  Map<String, dynamic>? statsFor(String customerId) => _customerStats[customerId];

  @override
  void dispose() {
    _loadGeneration++;
    super.dispose();
  }
}
