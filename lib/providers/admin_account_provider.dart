import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_fight/models/admin/admin_account_model.dart';
import 'package:food_fight/services/super_admin_service.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/utils/safe_change_notifier.dart';

/// Provider for managing Admin and Staff accounts in Super Admin panel
class AdminAccountProvider extends ChangeNotifier with SafeChangeNotifier {
  List<AdminAccountModel> _admins = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _roleFilter = 'all'; // 'all', 'admin', 'staff', 'super_admin'
  String _statusFilter = 'all'; // 'all', 'active', 'suspended', 'deactivated'
  String _branchFilter = 'all'; // 'all' or branchId
  StreamSubscription<List<AdminAccountModel>>? _subscription;

  List<AdminAccountModel> get admins => List.unmodifiable(_admins);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get roleFilter => _roleFilter;
  String get statusFilter => _statusFilter;
  String get branchFilter => _branchFilter;

  List<AdminAccountModel> get filteredAdmins {
    return _admins.where((a) {
      final matchesSearch = _searchQuery.isEmpty ||
          a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.phone.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesRole = _roleFilter == 'all' || a.role == _roleFilter;
      final matchesStatus = _statusFilter == 'all' || a.status == _statusFilter;
      final matchesBranch = _branchFilter == 'all' || a.branchId == _branchFilter;

      return matchesSearch && matchesRole && matchesStatus && matchesBranch;
    }).toList();
  }

  AdminAccountProvider();

  void init() {
    watchAdminAccounts();
  }

  /// Watch real-time admin accounts
  void watchAdminAccounts() {
    _isLoading = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    _subscription?.cancel();
    _subscription = SuperAdminService.watchAdminAccounts().listen(
      (data) {
        _admins = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load admin accounts: $e';
        AppLogger.error('AdminAccountProvider watch error: $e', tag: 'AdminAccountProvider');
        notifyListeners();
      },
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setRoleFilter(String role) {
    _roleFilter = role;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setBranchFilter(String branchId) {
    _branchFilter = branchId;
    notifyListeners();
  }

  /// Create new Admin/Staff account
  Future<bool> createAdminAccount(AdminAccountModel admin, {String? createdBy}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await SuperAdminService.createAdminAccount(admin, createdBy: createdBy);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create admin: $e';
      AppLogger.error('AdminAccountProvider create error: $e', tag: 'AdminAccountProvider');
      notifyListeners();
      return false;
    }
  }

  /// Update admin info and permissions
  Future<bool> updateAdminAccount(AdminAccountModel admin, {String? updatedBy}) async {
    try {
      await SuperAdminService.updateAdminAccount(admin, updatedBy: updatedBy);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update admin: $e';
      AppLogger.error('AdminAccountProvider update error: $e', tag: 'AdminAccountProvider');
      notifyListeners();
      return false;
    }
  }

  /// Set status: activate, deactivate, suspend
  Future<bool> setAdminStatus(String adminId, String newStatus, {String? changedBy}) async {
    try {
      await SuperAdminService.setAdminStatus(adminId, newStatus, changedBy: changedBy);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to change admin status: $e';
      AppLogger.error('AdminAccountProvider setStatus error: $e', tag: 'AdminAccountProvider');
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
