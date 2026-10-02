import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_fight/models/admin/audit_log_model.dart';
import 'package:food_fight/services/super_admin_service.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/utils/safe_change_notifier.dart';

/// Provider for monitoring system-wide audit logs
class AuditLogProvider extends ChangeNotifier with SafeChangeNotifier {
  List<AuditLogModel> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _entityFilter = 'all'; // 'all', 'order', 'menu', 'category', 'coupon', 'admin', 'system'
  String _searchQuery = '';
  StreamSubscription<List<AuditLogModel>>? _subscription;

  List<AuditLogModel> get logs => List.unmodifiable(_logs);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get entityFilter => _entityFilter;
  String get searchQuery => _searchQuery;

  AuditLogProvider() {
    init();
  }

  void init() {
    watchLogs();
  }

  /// Watch audit logs
  void watchLogs() {
    _isLoading = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    _subscription?.cancel();
    _subscription = SuperAdminService.watchAuditLogs(
      entityFilter: _entityFilter,
      search: _searchQuery,
    ).listen(
      (data) {
        _logs = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load audit logs: $e';
        AppLogger.error('AuditLogProvider error: $e', tag: 'AuditLogProvider');
        notifyListeners();
      },
    );
  }

  void setEntityFilter(String entity) {
    _entityFilter = entity;
    watchLogs();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    watchLogs();
  }

  /// Record action directly
  Future<void> recordLog({
    required String action,
    required String actorName,
    required String actorEmail,
    required String actorRole,
    required String targetEntity,
    required String targetId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    await SuperAdminService.recordAuditLog(AuditLogModel(
      id: '',
      action: action,
      actorName: actorName,
      actorEmail: actorEmail,
      actorRole: actorRole,
      targetEntity: targetEntity,
      targetId: targetId,
      description: description,
      metadata: metadata,
    ));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
