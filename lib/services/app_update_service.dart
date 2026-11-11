import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
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
    if (remoteBuild > 0 && localBuild > 0) {
      return remoteBuild > localBuild;
    }
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
      if (uri.scheme != 'https' || uri.userInfo.isNotEmpty || uri.port != 443) {
        return false;
      }
      return _kAllowedHosts.contains(uri.host);
    } catch (_) {
      return false;
    }
  }

  Future<Response<T>> _trustedAsset<T>(
    String url,
    Future<Response<T>> Function(String url, Options options) request, {
    ResponseType? responseType,
  }) async {
    const redirects = {301, 302, 303, 307, 308};
    for (var hop = 0; hop <= 5; hop++) {
      if (!_isAllowedUrl(url)) {
        throw StateError('Update asset points to an untrusted URL.');
      }
      final response = await request(
        url,
        Options(
          responseType: responseType,
          followRedirects: false,
          validateStatus: (code) => code == 200 || redirects.contains(code),
        ),
      );
      if (response.statusCode == 200) return response;
      final target = response.headers.value(HttpHeaders.locationHeader);
      if (target == null || target.isEmpty) {
        throw StateError('Update redirect is missing a destination.');
      }
      url = Uri.parse(url).resolve(target).toString();
    }
    throw StateError('Too many update redirects.');
  }

  ({String apkUrl, String checksumUrl, int? size})? testSelectApkAssets(
    List<dynamic> assets,
    String version,
  ) => _selectApkAssets(assets, version);

  ({String apkUrl, String checksumUrl, int? size})? _selectApkAssets(
    List<dynamic> assets,
    String version,
  ) {
    final byName = <String, Map<dynamic, dynamic>>{
      for (final asset in assets.whereType<Map>())
        if (asset['name'] is String) asset['name'] as String: asset,
    };
    final apkNames = byName.keys.where((name) => name.toLowerCase().endsWith('.apk'));
    final official = 'FoodFight_v${version}_release.apk';
    final name = byName.containsKey(official) ? official : apkNames.length == 1 ? apkNames.single : null;
    if (name == null) return null;

    final apk = byName[name]!;
    final apkUrl = apk['browser_download_url'];
    final checksumUrl = byName['$name.sha256']?['browser_download_url'];
    if (apkUrl is! String || checksumUrl is! String ||
        !_isAllowedUrl(apkUrl) || !_isAllowedUrl(checksumUrl)) {
      return null;
    }
    final size = apk['size'];
    return (apkUrl: apkUrl, checksumUrl: checksumUrl, size: size is int ? size : null);
  }

  Future<UpdateCheckResponse> checkForUpdate() async {
    try {
      final pkgInfo = await PackageInfo.fromPlatform();
      final currentVersion = pkgInfo.version;
      final currentBuild = int.tryParse(pkgInfo.buildNumber) ?? 0;

      final response = await _dio.get<Map<String, dynamic>>(
        _kGitHubApiUrl,
        options: Options(followRedirects: false),
      );
      if (response.statusCode != 200 || response.data == null) {
        return const UpdateCheckResponse(result: UpdateCheckResult.error, errorMessage: 'Bad response from GitHub');
      }

      final data = response.data!;
      final tag = (data['tag_name'] as String?) ?? '';
      final body = data['body'] as String?;
      final (remoteVersion, remoteBuild) = _parseTag(tag, body);
      if (remoteBuild <= 0) {
        return const UpdateCheckResponse(
          result: UpdateCheckResult.error,
          errorMessage: 'The release does not declare an Android build number.',
        );
      }

      final assets = data['assets'];
      final selected = _selectApkAssets(
        assets is List ? assets : const [],
        remoteVersion,
      );
      if (selected == null) {
        return const UpdateCheckResponse(
          result: UpdateCheckResult.error,
          errorMessage: 'Release is missing a unique trusted APK and its matching checksum.',
        );
      }
      final release = ReleaseInfo(
        tagName: tag,
        versionName: remoteVersion,
        buildNumber: remoteBuild,
        releaseNotes: body,
        apkDownloadUrl: selected.apkUrl,
        sha256Url: selected.checksumUrl,
        apkSizeBytes: selected.size,
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
      final checksumUrl = release.sha256Url;
      if (!_isAllowedUrl(release.apkDownloadUrl) ||
          checksumUrl == null || !_isAllowedUrl(checksumUrl)) {
        onError('Security: rejected download from untrusted host.');
        return;
      }

      final cancelToken = CancelToken();
      _downloadCancelToken = cancelToken;
      final tmpDir = await getTemporaryDirectory();
      _tempApkPath = '${tmpDir.path}/food-fight-update.apk';

      await _trustedAsset<dynamic>(
        release.apkDownloadUrl,
        (url, options) => _dio.download(
          url,
          _tempApkPath!,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (total > 0) onProgress(received / total * 0.95);
          },
        ),
      );

      onProgress(0.97);
      final verified = await _verifySha256(File(_tempApkPath!), checksumUrl, cancelToken);
      if (!verified) {
        await _cleanupTempFile();
        if (!cancelToken.isCancelled) {
          onError('Could not verify the APK checksum. Download the update again.');
        }
        return;
      }

      if (cancelToken.isCancelled) {
        await _cleanupTempFile();
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

      final errorCode = res?['errorCode'] as String? ?? 'VERIFY_ERROR';

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
        case 'OK':
          return const ApkPreInstallResult(
            status: ApkInstallStatus.ready,
            errorCode: 'OK',
            englishMessage: 'APK verified successfully.',
            romanUrduMessage: 'APK ki tasdeeq ho gayi hai.',
          );
        default:
          return ApkPreInstallResult(
            status: ApkInstallStatus.error,
            errorCode: errorCode,
            englishMessage: switch (errorCode) {
              'PACKAGE_MISMATCH' => 'This download belongs to a different app.',
              'FILE_NOT_FOUND' => 'The update file is missing. Download it again.',
              _ => 'Android could not verify this update.',
            },
            romanUrduMessage: 'Android update ki tasdeeq nahi kar saka.',
          );
      }
    } catch (e) {
      AppLogger.warn('Pre-install verification failed: $e', tag: 'AppUpdateService');
      return const ApkPreInstallResult(
        status: ApkInstallStatus.error,
        errorCode: 'VERIFY_ERROR',
        englishMessage: 'Android could not verify this update.',
        romanUrduMessage: 'Android update ki tasdeeq nahi kar saka.',
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
    final apkPath = _tempApkPath;
    if (apkPath == null || !Platform.isAndroid) return false;
    try {
      return await _verifierChannel.invokeMethod<bool>(
        'launchApkInstaller',
        {'apkPath': apkPath},
      ) ?? false;
    } catch (e) {
      AppLogger.error('Install failed: $e', tag: 'AppUpdateService');
      return false;
    }
  }

  Future<bool> _verifySha256(File apkFile, String sha256Url, CancelToken cancelToken) async {
    try {
      final hashResp = await _trustedAsset<String>(
        sha256Url,
        (url, options) => _dio.get<String>(url, options: options, cancelToken: cancelToken),
        responseType: ResponseType.plain,
      );
      if (hashResp.statusCode != 200 || hashResp.data == null) return false;
      final expected = hashResp.data!.trim().split(RegExp(r'\s+')).first.toLowerCase();
      if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(expected)) return false;
      final actual = (await sha256.bind(apkFile.openRead()).single).toString();
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
  Future<Response<T>> testTrustedAsset<T>(
    String url,
    Future<Response<T>> Function(String url, Options options) request,
  ) => _trustedAsset(url, request);

  /// @visibleForTesting
  bool testIsAllowedUrl(String url) => _isAllowedUrl(url);
  /// @visibleForTesting
  bool testIsNewer(String remote, String local, int remoteBuild, int localBuild) =>
      _isNewerVersion(remote, local, remoteBuild, localBuild);
  /// @visibleForTesting
  (String versionName, int buildNumber) testParseTag(String tag, String? body) =>
      _parseTag(tag, body);
}
