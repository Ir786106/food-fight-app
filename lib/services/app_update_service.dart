import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
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

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._();
  factory AppUpdateService() => _instance;
  AppUpdateService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
  ));

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

  Future<bool> installApk() async {
    if (_tempApkPath == null) return false;
    try {
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
