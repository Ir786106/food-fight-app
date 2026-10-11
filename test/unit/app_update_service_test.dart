import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/services/app_update_service.dart';

void main() {
  late AppUpdateService svc;

  setUp(() {
    svc = AppUpdateService();
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

  group('Release JSON parsing', () {
    test('finds APK and SHA256 assets', () {
      final assets = [
        {'name': 'food-fight-v1.7.0.apk', 'browser_download_url': 'https://objects.githubusercontent.com/app.apk', 'size': 65000000},
        {'name': 'food-fight-v1.7.0.apk.sha256', 'browser_download_url': 'https://objects.githubusercontent.com/app.apk.sha256', 'size': 72},
      ];
      final apk = assets.firstWhere((a) => (a['name'] as String).endsWith('.apk'), orElse: () => {});
      final sha = assets.firstWhere((a) => (a['name'] as String).endsWith('.apk.sha256'), orElse: () => {});
      expect(apk.isNotEmpty, isTrue);
      expect(sha.isNotEmpty, isTrue);
    });
    test('handles missing SHA256 gracefully', () {
      final assets = [
        {'name': 'food-fight-v1.7.0.apk', 'browser_download_url': 'https://objects.githubusercontent.com/app.apk', 'size': 65000000},
      ];
      final sha = assets.firstWhere((a) => (a['name'] as String).endsWith('.apk.sha256'), orElse: () => {});
      expect(sha.isEmpty, isTrue);
    });
  });
}
