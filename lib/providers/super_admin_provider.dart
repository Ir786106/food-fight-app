import '../models/report_model.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_fight/models/admin/system_settings_model.dart';
import 'package:food_fight/services/super_admin_service.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/errors/platform_operation_error.dart';
import 'package:food_fight/core/utils/safe_change_notifier.dart';

/// Provider for Super Admin Dashboard KPIs and global platform configuration
class SuperAdminProvider extends ChangeNotifier with SafeChangeNotifier {
  Map<String, dynamic> _metrics = const {};

  SystemSettingsModel _settings = SystemSettingsModel();
  bool _isLoading = false;
  String? _errorMessage;
  String? _settingsError;
  String? _settingsSaveError;
  bool _isSavingSettings = false;
  bool _settingsReady = false;
  StreamSubscription<SystemSettingsModel>? _settingsSub;

  Map<String, dynamic> get metrics => _metrics;
  SystemSettingsModel get settings => _settings;
  bool get settingsReady => _settingsReady;
  String? get settingsError => _settingsError;
  String? get settingsSaveError => _settingsSaveError;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalRestaurants => _metrics['totalRestaurants'] as int? ?? 0;
  int get totalBranches => _metrics['totalBranches'] as int? ?? 0;
  int get activeRiders => _metrics['activeRiders'] as int? ?? 0;
  int get totalCustomers => _metrics['totalCustomers'] as int? ?? 0;
  int get totalAdmins => _metrics['totalAdmins'] as int? ?? 0;
  int get totalStaff => _metrics['totalStaff'] as int? ?? 0;
  int get totalRiders => _metrics['totalRiders'] as int? ?? 0;
  int get totalOrders => _metrics['totalOrders'] as int? ?? 0;
  int get completedOrders => _metrics['completedOrders'] as int? ?? 0;
  int get cancelledOrders => _metrics['cancelledOrders'] as int? ?? 0;
  double get deliveredGmv =>
      (_metrics['deliveredGmv'] as num? ?? 0.0).toDouble();

  List<DailySalesStat> get dailySales => [
        for (final day
            in (_metrics['dailySales'] as List? ?? const []).whereType<Map>())
          DailySalesStat(
            date: DateTime.fromMillisecondsSinceEpoch(day['date'] as int,
                isUtc: true),
            revenue: (day['revenue'] as num).toDouble(),
            ordersCount: day['ordersCount'] as int,
          ),
      ];
  bool _initialized = false;

  SuperAdminProvider();

  void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    init();
  }

  void init() {
    loadMetrics();
    ensureSettingsWatching();
  }

  /// Load platform-wide metrics
  Future<void> loadMetrics() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    try {
      _metrics = await SuperAdminService.getPlatformMetrics();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = platformOperationError(e,
          fallback: 'Unable to load platform metrics. Please try again.');
      AppLogger.error('SuperAdminProvider metrics error: $e',
          tag: 'SuperAdminProvider');
      notifyListeners();
    }
  }

  /// Watch global settings
  void ensureSettingsWatching() {
    if (_settingsSub == null) watchSettings();
  }

  void watchSettings() {
    _settingsError = null;
    _settingsReady = false;
    notifyListenersPostFrame();
    _settingsSub?.cancel();
    _settingsSub = SuperAdminService.watchSystemSettings().listen(
      (s) {
        _settings = s;
        _settingsReady = true;
        _settingsError = null;
        notifyListeners();
      },
      onError: (e) {
        _settingsError = 'Unable to load system settings. Please try again.';
        AppLogger.error('SuperAdminProvider settings watch error: $e',
            tag: 'SuperAdminProvider');
        notifyListeners();
      },
    );
  }

  /// Update and save platform settings
  Future<bool> saveSettings(SystemSettingsModel newSettings,
      {String? savedBy}) async {
    if (_isSavingSettings) return false;
    _isSavingSettings = true;
    _settingsSaveError = null;
    notifyListeners();

    try {
      await SuperAdminService.saveSystemSettings(newSettings, savedBy: savedBy);
      _settings = newSettings;
      return true;
    } catch (e) {
      _settingsSaveError = platformOperationError(e,
          fallback: 'Unable to save system settings. Please try again.');
      AppLogger.error('SuperAdminProvider saveSettings error: $e',
          tag: 'SuperAdminProvider');
      return false;
    } finally {
      _isSavingSettings = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    super.dispose();
  }
}
