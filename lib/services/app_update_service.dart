import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/utils/logger.dart';

/// Allowed CDN hosts for APK downloads -- never download from anywhere else.
const _kAllowedHosts = {
  'github.com',
  'objects.githubusercontent.com',
  'release-assets.githubusercontent.com',
  'releases.githubusercontent.com',
};

const _kGitHubApiUrl = 'https://api.github.com/repos/Ir786106/food-fight-app/releases/latest';

class ReleaseInfo {
  final String tagName;
  final String versionName;
  final int buildNumber;
  final String? releaseNotes;
  final String apkDownloadUrl;
  final String? sha256Url;
  final int? apkSizeBytes;

  const ReleaseInfo({
    required this.tagName,
    required this.versionName,
    required this.buildNumber,
    this.releaseNotes,
    required this.apkDownloadUrl,
    this.sha256Url,
    this.apkSizeBytes,
  });
}

enum UpdateCheckResult { upToDate, updateAvailable, error }

class UpdateCheckResponse {
  final UpdateCheckResult result;
  final ReleaseInfo? release;
  final String? errorMessage;

  const UpdateCheckResponse({
    required this.result,
    this.release,
    this.errorMessage,
  });
}

enum ApkInstallStatus {
  ready,
  signatureMismatch,
  versionDowngrade,
  insufficientStorage,
  unknownSourcesBlocked,
  parseError,
  error,
}

class ApkPreInstallResult {
  final ApkInstallStatus status;
  final String errorCode;
  final String englishMessage;
  final String romanUrduMessage;
  final String releasePageUrl;

  const ApkPreInstallResult({
    required this.status,
    required this.errorCode,
    required this.englishMessage,
    required this.romanUrduMessage,
    this.releasePageUrl = 'https://github.com/Ir786106/food-fight-app/releases/latest',
  });

  bool get canInstall => status == ApkInstallStatus.ready;
}

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._();
  factory AppUpdateService() => _instance;
  AppUpdateService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
  ));

  static const MethodChannel _verifierChannel =
      MethodChannel('com.example.food_fight/package_verifier');

  CancelToken? _downloadCancelToken;
  String? _tempApkPath;

  /// Parse version tag like "v1.7.0+8" or "v1.7.0" into (versionName, buildNumber).
  (String versionName, int buildNumber) _parseTag(String tag, String? body) {
    final raw = tag.startsWith('v') ? tag.substring(1) : tag;
    final plusIdx = raw.indexOf('+');
    if (plusIdx != -1) {
      return (raw.substring(0, plusIdx), int.tryParse(raw.substring(plusIdx + 1)) ?? 0);
    }
    if (body != null) {
      final match = RegExp(r'[Bb]uild[:\s]+(\d+)').firstMatch(body);
      if (match != null) return (raw, int.tryParse(match.group(1)!) ?? 0);
    }
    return (raw, 0);
  }

  bool _isNewerVersion(String remote, String local, int remoteBuild, int localBuild) {
    final rv = _parseParts(remote);
    final lv = _parseParts(local);
    for (int i = 0; i < 3; i++) {
      if (rv[i] > lv[i]) return true;
      if (rv[i] < lv[i]) return false;
    }
    return remoteBuild > localBuild;
  }

  List<int> _parseParts(String v) {
    final p = v.split('.');
    return [
      int.tryParse(p.isNotEmpty ? p[0] : '0') ?? 0,
      int.tryParse(p.length > 1 ? p[1] : '0') ?? 0,
      int.tryParse(p.length > 2 ? p[2] : '0') ?? 0,
    ];
  }

  bool _isAllowedUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'https') return false;
      return _kAllowedHosts.contains(uri.host);
    } catch (_) {
      return false;
    }
  }

  Future<UpdateCheckResponse> checkForUpdate() async {
    try {
      final pkgInfo = await PackageInfo.fromPlatform();
      final currentVersion = pkgInfo.version;
      final currentBuild = int.tryParse(pkgInfo.buildNumber) ?? 0;

      final response = await _dio.get<Map<String, dynamic>>(_kGitHubApiUrl);
      if (response.statusCode != 200 || response.data == null) {
        return const UpdateCheckResponse(result: UpdateCheckResult.error, errorMessage: 'Bad response from GitHub');
      }

      final data = response.data!;
      final tag = (data['tag_name'] as String?) ?? '';
      final body = data['body'] as String?;
      final (remoteVersion, remoteBuild) = _parseTag(tag, body);

      final assets = (data['assets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final apkAsset = assets.firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => <String, dynamic>{},
      );
      if (apkAsset.isEmpty) {
        return const UpdateCheckResponse(result: UpdateCheckResult.error, errorMessage: 'No APK asset in release');
      }

      final apkUrl = apkAsset['browser_download_url'] as String? ?? '';
      if (!_isAllowedUrl(apkUrl)) {
        return const UpdateCheckResponse(result: UpdateCheckResult.error, errorMessage: 'Untrusted download host');
      }

      final sha256Asset = assets.firstWhere(
        (a) => (a['name'] as String).endsWith('.apk.sha256'),
        orElse: () => <String, dynamic>{},
      );
      final sha256Url = sha256Asset.isNotEmpty ? sha256Asset['browser_download_url'] as String? : null;

      final release = ReleaseInfo(
        tagName: tag,
        versionName: remoteVersion,
        buildNumber: remoteBuild,
        releaseNotes: body,
        apkDownloadUrl: apkUrl,
        sha256Url: sha256Url,
        apkSizeBytes: apkAsset['size'] as int?,
      );

      if (_isNewerVersion(remoteVersion, currentVersion, remoteBuild, currentBuild)) {
        return UpdateCheckResponse(result: UpdateCheckResult.updateAvailable, release: release);
      }
      return const UpdateCheckResponse(result: UpdateCheckResult.upToDate);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 429) {
        return const UpdateCheckResponse(result: UpdateCheckResult.error, errorMessage: 'GitHub rate limit');
      }
      return const UpdateCheckResponse(result: UpdateCheckResult.error, errorMessage: 'Network unavailable');
    } catch (e) {
      AppLogger.error('Update check failed: $e', tag: 'AppUpdateService');
      return UpdateCheckResponse(result: UpdateCheckResult.error, errorMessage: e.toString());
    }
  }

  Future<void> downloadAndInstall({
    required ReleaseInfo release,
    required void Function(double progress) onProgress,
    required void Function(String error) onError,
    required void Function() onInstallReady,
  }) async {
    try {
      if (!_isAllowedUrl(release.apkDownloadUrl)) {
        onError('Security: rejected download from untrusted host.');
        return;
      }

      final tmpDir = await getTemporaryDirectory();
      _tempApkPath = '${tmpDir.path}/food-fight-${release.tagName}.apk';
      _downloadCancelToken = CancelToken();

      await _dio.download(
        release.apkDownloadUrl,
        _tempApkPath!,
        cancelToken: _downloadCancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total * 0.95);
        },
      );

      if (release.sha256Url != null && _isAllowedUrl(release.sha256Url!)) {
        onProgress(0.97);
        final verified = await _verifySha256(File(_tempApkPath!), release.sha256Url!);
        if (!verified) {
          await _cleanupTempFile();
          onError('Security: SHA-256 checksum mismatch. APK deleted for safety.');
          return;
        }
      } else {
        await _cleanupTempFile();
        onError('Security: No SHA-256 checksum available. Install aborted.');
        return;
      }

      onProgress(1.0);
      onInstallReady();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        await _cleanupTempFile();
        return;
      }
      onError('Download failed: ${e.message}');
      await _cleanupTempFile();
    } catch (e) {
      onError('Update error: $e');
      await _cleanupTempFile();
    }
  }

  Future<ApkPreInstallResult> verifyApkBeforeInstall() async {
    if (_tempApkPath == null) {
      return const ApkPreInstallResult(
        status: ApkInstallStatus.error,
        errorCode: 'FILE_NOT_FOUND',
        englishMessage: 'No downloaded APK file found to install.',
        romanUrduMessage: 'Install karne ke liye koi downloaded file nahi mili.',
      );
    }

    if (!Platform.isAndroid) {
      return const ApkPreInstallResult(
        status: ApkInstallStatus.ready,
        errorCode: 'OK',
        englishMessage: 'Ready to install.',
        romanUrduMessage: 'Install ke liye tayyar.',
      );
    }

    try {
      final res = await _verifierChannel.invokeMapMethod<String, dynamic>(
        'verifyApk',
        {'apkPath': _tempApkPath},
      );

      final errorCode = res?['errorCode'] as String? ?? 'OK';

      switch (errorCode) {
        case 'SIGNATURE_MISMATCH':
          return const ApkPreInstallResult(
            status: ApkInstallStatus.signatureMismatch,
            errorCode: 'SIGNATURE_MISMATCH',
            englishMessage:
                'This update was signed with a different key. Uninstall the app once and install again.',
            romanUrduMessage:
                'Yeh update mukhtalif key se sign ki gayi hai. Barah-e-karam pehle purani app uninstall karein, phir naya version install karein.',
          );
        case 'VERSION_DOWNGRADE':
          return const ApkPreInstallResult(
            status: ApkInstallStatus.versionDowngrade,
            errorCode: 'VERSION_DOWNGRADE',
            englishMessage:
                'A newer or identical version is already installed on your device.',
            romanUrduMessage:
                'Aap ke phone mein pehle se naya ya yahi version mojood hai.',
          );
        case 'INSUFFICIENT_STORAGE':
          return const ApkPreInstallResult(
            status: ApkInstallStatus.insufficientStorage,
            errorCode: 'INSUFFICIENT_STORAGE',
            englishMessage:
                'Insufficient storage space. Please free up at least 150MB of internal storage.',
            romanUrduMessage:
                'Phone ki memory kam hai. Barah-e-karam thori storage khali karein.',
          );
        case 'UNKNOWN_SOURCES_BLOCKED':
          return const ApkPreInstallResult(
            status: ApkInstallStatus.unknownSourcesBlocked,
            errorCode: 'UNKNOWN_SOURCES_BLOCKED',
            englishMessage:
                'Installation from unknown sources is blocked. Please enable permission in Settings.',
            romanUrduMessage:
                'Unknown sources se install band hai. Settings mein ja kar ijazat on karein.',
          );
        case 'PARSE_ERROR':
          return const ApkPreInstallResult(
            status: ApkInstallStatus.parseError,
            errorCode: 'PARSE_ERROR',
            englishMessage:
                'Downloaded APK is corrupted or incomplete. Please download again.',
            romanUrduMessage:
                'Downloaded APK kharab ya na-mukammal hai. Dobara download karein.',
          );
        default:
          return const ApkPreInstallResult(
            status: ApkInstallStatus.ready,
            errorCode: 'OK',
            englishMessage: 'APK verified successfully.',
            romanUrduMessage: 'APK ki tasdeeq ho gayi hai.',
          );
      }
    } catch (e) {
      AppLogger.warn('Pre-install verification notice ($e), allowing system installer to proceed', tag: 'AppUpdateService');
      return const ApkPreInstallResult(
        status: ApkInstallStatus.ready,
        errorCode: 'OK',
        englishMessage: 'Ready to install.',
        romanUrduMessage: 'Install ke liye tayyar.',
      );
    }
  }

  Future<void> openUnknownSourcesSettings() async {
    try {
      if (Platform.isAndroid) {
        await _verifierChannel.invokeMethod('openInstallUnknownAppsSettings');
      }
    } catch (e) {
      AppLogger.warn('Failed to open unknown sources settings: $e', tag: 'AppUpdateService');
    }
  }

  Future<bool> installApk() async {
    if (_tempApkPath == null) return false;
    try {
      final precheck = await verifyApkBeforeInstall();
      if (!precheck.canInstall) {
        AppLogger.warn('Install aborted due to pre-check: ${precheck.errorCode}', tag: 'AppUpdateService');
        return false;
      }
      final result = await OpenFilex.open(_tempApkPath!, type: 'application/vnd.android.package-archive');
      Future.delayed(const Duration(seconds: 90), _cleanupTempFile);
      return result.type == ResultType.done;
    } catch (e) {
      AppLogger.error('Install failed: $e', tag: 'AppUpdateService');
      return false;
    }
  }

  Future<bool> _verifySha256(File apkFile, String sha256Url) async {
    try {
      final hashResp = await _dio.get<String>(sha256Url, options: Options(responseType: ResponseType.plain));
      if (hashResp.statusCode != 200 || hashResp.data == null) return false;
      final expected = hashResp.data!.trim().split(RegExp(r'\s+')).first.toLowerCase();
      if (expected.length != 64) return false;
      final bytes = await apkFile.readAsBytes();
      final actual = sha256.convert(bytes).toString().toLowerCase();
      return expected == actual;
    } catch (e) {
      AppLogger.error('Hash verify error: $e', tag: 'AppUpdateService');
      return false;
    }
  }

  void cancelDownload() => _downloadCancelToken?.cancel('User cancelled');

  Future<void> _cleanupTempFile() async {
    try {
      if (_tempApkPath != null) {
        final f = File(_tempApkPath!);
        if (await f.exists()) await f.delete();
        _tempApkPath = null;
      }
    } catch (_) {}
  }

  // Test-accessible wrappers (no-op in production, used by unit tests)
  /// @visibleForTesting
  bool testIsAllowedUrl(String url) => _isAllowedUrl(url);
  /// @visibleForTesting
  bool testIsNewer(String remote, String local, int remoteBuild, int localBuild) =>
      _isNewerVersion(remote, local, remoteBuild, localBuild);
  /// @visibleForTesting
  (String versionName, int buildNumber) testParseTag(String tag, String? body) =>
      _parseTag(tag, body);
}
