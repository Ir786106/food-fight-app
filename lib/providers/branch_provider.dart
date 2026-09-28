import 'dart:async';
import 'package:flutter/material.dart';
import '../models/branch_model.dart';
import '../services/branch_service.dart';
import '../core/utils/logger.dart';

enum BranchSortField { revenue, orderCount, profit, name }
typedef BranchSortOption = BranchSortField;

/// Manages multi-branch states for Customer storefront, Admin branch-scoping, and Super Admin oversight
class BranchProvider extends ChangeNotifier {
  List<BranchModel> _branches = [];
  BranchModel? _selectedBranch;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<BranchModel>>? _branchesSub;
  BranchSortField _sortField = BranchSortField.revenue;
  bool _sortAscending = false;

  List<BranchModel> get branches => List.unmodifiable(_branches);
  List<BranchModel> get activeBranches =>
      _branches.where((b) => b.isActive).toList();

  BranchModel? get selectedBranch => _selectedBranch ?? (_branches.isNotEmpty ? _branches.first : null);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BranchSortField get sortField => _sortField;
  bool get sortAscending => _sortAscending;

  BranchProvider() {
    init();
  }

  /// Initialize real-time listener and seed default branches if necessary
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await BranchService.seedInitialBranchesIfEmpty();
    } catch (e) {
      AppLogger.warn('Branch seeding check: $e', tag: 'BranchProvider');
    }

    _branchesSub?.cancel();
    _branchesSub = BranchService.watchBranches().listen(
      (list) {
        _branches = list;
        _isLoading = false;
        _errorMessage = null;

        // Auto-select first active branch if currently unselected or invalidated
        if (_selectedBranch == null && _branches.isNotEmpty) {
          _selectedBranch = _branches.firstWhere((b) => b.isActive, orElse: () => _branches.first);
        } else if (_selectedBranch != null) {
          // Update selected instance with fresh data from firestore
          final updated = _branches.where((b) => b.id == _selectedBranch!.id).firstOrNull;
          if (updated != null) {
            _selectedBranch = updated;
          }
        }

        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load branches: $e';
        AppLogger.error('Branch stream error: $e', tag: 'BranchProvider');
        notifyListeners();
      },
    );
  }

  /// Select active branch (Customer browsing or Super Admin filtering)
  void selectBranch(BranchModel branch) {
    if (_selectedBranch?.id != branch.id) {
      _selectedBranch = branch;
      notifyListeners();
    }
  }

  /// Select branch by ID
  void selectBranchById(String branchId) {
    if (branchId.isEmpty) return;
    final match = _branches.where((b) => b.id == branchId).firstOrNull;
    if (match != null) {
      selectBranch(match);
    }
  }

  /// Set sorting criteria for Super Admin branch performance comparison
  void setSort(BranchSortField field, {bool? ascending}) {
    if (_sortField == field && ascending == null) {
      _sortAscending = !_sortAscending;
    } else {
      _sortField = field;
      _sortAscending = ascending ?? false;
    }
    notifyListeners();
  }

  /// Get sorted list of branches for Super Admin Performance table
  List<BranchModel> get sortedBranches {
    final list = List<BranchModel>.from(_branches);
    list.sort((a, b) {
      int cmp = 0;
      switch (_sortField) {
        case BranchSortField.revenue:
          cmp = a.revenue.compareTo(b.revenue);
          break;
        case BranchSortField.orderCount:
          cmp = a.orderCount.compareTo(b.orderCount);
          break;
        case BranchSortField.profit:
          cmp = a.profit.compareTo(b.profit);
          break;
        case BranchSortField.name:
          cmp = a.name.compareTo(b.name);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  /// Platform aggregates across all branches (Super Admin HQ)
  double get totalRevenue => _branches.fold(0.0, (sum, b) => sum + b.revenue);
  int get totalOrders => _branches.fold(0, (sum, b) => sum + b.orderCount);
  double get totalExpenses => _branches.fold(0.0, (sum, b) => sum + b.expenses);
  double get totalProfit => totalRevenue - totalExpenses;

  double get totalPlatformRevenue => totalRevenue;
  double get totalPlatformExpenses => totalExpenses;
  double get totalPlatformProfit => totalProfit;
  BranchSortField get selectedSort => _sortField;
  void setSortOption(BranchSortField field) => setSort(field);

  /// Create new branch (Super Admin "Add New Branch" workflow)
  Future<String> createBranch(BranchModel branch) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await BranchService.createBranch(branch);
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create branch: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update branch
  Future<void> updateBranch(BranchModel branch) async {
    _isLoading = true;
    notifyListeners();

    try {
      await BranchService.updateBranch(branch);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update branch: $e';
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _branchesSub?.cancel();
    super.dispose();
  }
}
