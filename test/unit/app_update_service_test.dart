import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/services/app_update_service.dart';

void main() {
  late AppUpdateService svc;

  setUp(() {
    svc = AppUpdateService();
  });

  test('blocks an untrusted redirect before requesting the destination', () async {
    final visited = <String>[];
    await expectLater(
      svc.testTrustedAsset<String>('https://github.com/release.apk', (url, options) async {
        visited.add(url);
        expect(options.followRedirects, isFalse);
        return Response<String>(
          requestOptions: RequestOptions(path: url),
          statusCode: 302,
          headers: Headers.fromMap({'location': ['https://untrusted.example/release.apk']}),
        );
      }),
      throwsStateError,
    );
    expect(visited, ['https://github.com/release.apk']);
  });

  test('Android version code wins when display versions differ', () {
    expect(svc.testIsNewer('1.7.9', '1.8.0', 18, 17), isTrue);
    expect(svc.testIsNewer('2.0.0', '1.8.0', 16, 17), isFalse);
  });

  group('Version comparison', () {
    test('newer major version is detected', () {
      expect(svc.testIsNewer('2.0.0', '1.9.9', 1, 0), isTrue);
    });
    test('newer minor version is detected', () {
      expect(svc.testIsNewer('1.8.0', '1.7.9', 1, 0), isTrue);
    });
    test('newer patch version is detected', () {
      expect(svc.testIsNewer('1.7.1', '1.7.0', 1, 0), isTrue);
    });
    test('same version different build number', () {
      expect(svc.testIsNewer('1.7.0', '1.7.0', 9, 8), isTrue);
    });
    test('up-to-date returns false', () {
      expect(svc.testIsNewer('1.7.0', '1.7.0', 8, 8), isFalse);
    });
    test('newer release name needs a higher Android build number when known', () {
      expect(svc.testIsNewer('1.9.0', '1.8.0', 17, 17), isFalse);
      expect(svc.testIsNewer('1.9.0', '1.8.0', 16, 17), isFalse);
      expect(svc.testIsNewer('1.9.0', '1.8.0', 18, 17), isTrue);
      expect(svc.testIsNewer('1.9.0', '1.8.0', 0, 17), isTrue);
    });
    test('older version returns false', () {
      expect(svc.testIsNewer('1.6.0', '1.7.0', 1, 8), isFalse);
    });
  });

  group('Tag parsing', () {
    test('parses v1.7.0+8 correctly', () {
      final (v, b) = svc.testParseTag('v1.7.0+8', null);
      expect(v, '1.7.0');
      expect(b, 8);
    });
    test('parses v1.7.0 with body fallback', () {
      final (v, b) = svc.testParseTag('v1.7.0', 'Build: 12');
      expect(v, '1.7.0');
      expect(b, 12);
    });
    test('parses v2.0.0 without build number', () {
      final (v, b) = svc.testParseTag('v2.0.0', null);
      expect(v, '2.0.0');
      expect(b, 0);
    });
  });

  group('URL allowlist', () {
    test('allows github.com', () {
      expect(svc.testIsAllowedUrl('https://github.com/user/repo/releases/download/v1/app.apk'), isTrue);
    });
    test('allows objects.githubusercontent.com', () {
      expect(svc.testIsAllowedUrl('https://objects.githubusercontent.com/github-production-release-asset-1234/app.apk'), isTrue);
    });
    test('rejects http (cleartext)', () {
      expect(svc.testIsAllowedUrl('http://github.com/user/repo/releases/download/v1/app.apk'), isFalse);
    });
    test('rejects unknown host', () {
      expect(svc.testIsAllowedUrl('https://malicious-site.com/app.apk'), isFalse);
    });
    test('rejects empty string', () {
      expect(svc.testIsAllowedUrl(''), isFalse);
    });
  });

  group('Android release assets', () {
    Map<String, Object> asset(String name) => {
      'name': name,
      'browser_download_url': 'https://github.com/releases/$name',
      'size': 64000000,
    };

    test('prefers the published universal APK and its own checksum', () {
      final files = [
        asset('staff.apk'),
        asset('staff.apk.sha256'),
        asset('FoodFight_v1.8.0_release.apk'),
        asset('FoodFight_v1.8.0_release.apk.sha256'),
        asset('Food Fight Setup.exe'),
      ];
      final selected = svc.testSelectApkAssets(files, '1.8.0');
      expect(selected?.apkUrl, endsWith('FoodFight_v1.8.0_release.apk'));
      expect(selected?.checksumUrl, endsWith('FoodFight_v1.8.0_release.apk.sha256'));
    });

    test('keeps a single older APK compatible and rejects a missing checksum', () {
      final old = asset('food-fight-v1.7.0.apk');
      expect(svc.testSelectApkAssets([old], '1.7.0'), isNull);
      expect(svc.testSelectApkAssets([old, asset('food-fight-v1.7.0.apk.sha256')], '1.7.0'),
          isNotNull);
    });

    test('rejects ambiguous APKs and checksums hosted outside the allowlist', () {
      expect(svc.testSelectApkAssets([
        asset('rider.apk'), asset('customer.apk'),
      ], '1.8.0'), isNull);
      expect(svc.testSelectApkAssets([
        asset('FoodFight_v1.8.0_release.apk'),
        {...asset('FoodFight_v1.8.0_release.apk.sha256'),
          'browser_download_url': 'https://example.test/hash'},
      ], '1.8.0'), isNull);
    });
  });

}
