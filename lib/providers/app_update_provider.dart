import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../services/app_update_service.dart';

const _kLastCheckedPref = 'ff_update_last_checked';
const _kSkippedVersionPref = 'ff_update_skipped_version';
const _kSkippedAtPref = 'ff_update_skipped_at';
const _kThrottleHours = 6;
const _kSkipDurationHours = 24;

class ForceUpdateConfig {
  final String minSupportedVersion;
  final bool forceUpdate;
  final String message;

  const ForceUpdateConfig({
    this.minSupportedVersion = '0.0.0',
    this.forceUpdate = false,
    this.message = 'Please update the app to continue.',
  });
}

class AppUpdateProvider extends ChangeNotifier {
  final AppUpdateService _service = AppUpdateService();

  ReleaseInfo? _availableRelease;
  ForceUpdateConfig? _forceConfig;
  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  bool _installReady = false;
  ApkPreInstallResult? _precheckResult;

  ReleaseInfo? get availableRelease => _availableRelease;
  ForceUpdateConfig? get forceConfig => _forceConfig;
  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get installReady => _installReady;
  ApkPreInstallResult? get precheckResult => _precheckResult;
  bool get hasUpdate => _availableRelease != null;
  bool get isForceUpdate => _forceConfig?.forceUpdate == true && hasUpdate;

  /// Called once after splash (non-blocking) and on resume with throttle.
  Future<void> checkForUpdateThrottled({bool force = false}) async {
    if (_isChecking) return;
    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckedMs = prefs.getInt(_kLastCheckedPref) ?? 0;
      final hoursSince = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastCheckedMs),
      ).inHours;
      if (hoursSince < _kThrottleHours) return;
    }
    await _doCheck();
  }

  Future<void> checkForUpdateNow() => _doCheck();

  Future<void> _doCheck() async {
    _isChecking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check Firestore force-update config (best effort)
      await _loadForceConfig();

      final response = await _service.checkForUpdate();
      if (response.result == UpdateCheckResult.updateAvailable) {
        // Check if user skipped this version recently
        final skipped = await _isVersionSkipped(response.release!.versionName);
        if (!skipped || isForceUpdate) {
          _availableRelease = response.release;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastCheckedPref, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.warn('Update check error: $e', tag: 'AppUpdateProvider');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> _loadForceConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.collectionSettings)
          .doc('app_update')
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists) {
        final d = doc.data()!;
        _forceConfig = ForceUpdateConfig(
          minSupportedVersion: d['minSupportedVersion'] as String? ?? '0.0.0',
          forceUpdate: d['forceUpdate'] as bool? ?? false,
          message: d['message'] as String? ?? 'Please update the app to continue.',
        );
      }
    } catch (_) {
      // Non-critical: ignore Firestore failures
    }
  }

  Future<bool> _isVersionSkipped(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skippedVersion = prefs.getString(_kSkippedVersionPref);
      if (skippedVersion != version) return false;
      final skippedAtMs = prefs.getInt(_kSkippedAtPref) ?? 0;
      final hoursSince = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(skippedAtMs))
          .inHours;
      return hoursSince < _kSkipDurationHours;
    } catch (_) {
      return false;
    }
  }

  Future<void> skipVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSkippedVersionPref, version);
      await prefs.setInt(_kSkippedAtPref, DateTime.now().millisecondsSinceEpoch);
      _availableRelease = null;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> startDownload() async {
    if (_availableRelease == null || _isDownloading) return;
    _isDownloading = true;
    _downloadProgress = 0;
    _errorMessage = null;
    _installReady = false;
    notifyListeners();

    await _service.downloadAndInstall(
      release: _availableRelease!,
      onProgress: (p) {
        _downloadProgress = p;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err;
        _isDownloading = false;
        notifyListeners();
      },
      onInstallReady: () {
        _installReady = true;
        _isDownloading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> installApk() async {
    _precheckResult = await _service.verifyApkBeforeInstall();
    if (!_precheckResult!.canInstall) {
      _errorMessage = '${_precheckResult!.englishMessage}\n\n${_precheckResult!.romanUrduMessage}';
      notifyListeners();
      return false;
    }
    return await _service.installApk();
  }

  Future<void> openUnknownSourcesSettings() async {
    await _service.openUnknownSourcesSettings();
  }

  void cancelDownload() {
    _service.cancelDownload();
    _isDownloading = false;
    _downloadProgress = 0;
    notifyListeners();
  }

  void dismissUpdate() {
    _availableRelease = null;
    _errorMessage = null;
    _installReady = false;
    _isDownloading = false;
    notifyListeners();
  }

  /// Super-admin: update force-update config in Firestore.
  Future<void> updateForceConfig({
    required String minSupportedVersion,
    required bool forceUpdate,
    required String message,
  }) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.collectionSettings)
        .doc('app_update')
        .set({
      'minSupportedVersion': minSupportedVersion,
      'forceUpdate': forceUpdate,
      'message': message,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _forceConfig = ForceUpdateConfig(
      minSupportedVersion: minSupportedVersion,
      forceUpdate: forceUpdate,
      message: message,
    );
    notifyListeners();
  }
}
