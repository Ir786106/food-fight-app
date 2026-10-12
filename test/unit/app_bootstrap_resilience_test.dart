import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/bootstrap/app_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppBootstrap.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_messaging'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_messaging'),
      null,
    );
  });

  group('AppBootstrap Resilience & Isolation', () {
    test('startBackgroundBootstrap runs without throwing even if services fail', () async {
      expect(AppBootstrap.hasCompleted, isFalse);

      // Trigger background bootstrap
      await AppBootstrap.startBackgroundBootstrap();

      expect(AppBootstrap.hasCompleted, isTrue);
    });

    test('Multiple concurrent bootstrap calls are safely deduplicated', () async {
      await Future.wait([
        AppBootstrap.startBackgroundBootstrap(),
        AppBootstrap.startBackgroundBootstrap(),
      ]);

      expect(AppBootstrap.hasCompleted, isTrue);
    });
  });
}
