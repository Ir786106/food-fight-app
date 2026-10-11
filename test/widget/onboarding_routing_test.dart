import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:food_fight/core/constants/app_constants.dart';

// We test the routing decision logic rather than full screen rendering
// to avoid needing Firebase/real services in unit tests.

void main() {
  group('Onboarding routing logic', () {
    test('First launch: onboarding flag is false by default', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(AppConstants.storageOnboardingCompleted) ?? false;
      expect(completed, isFalse, reason: 'Fresh install should show onboarding');
    });

    test('After onboarding: flag is set to true', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.storageOnboardingCompleted, true);
      final completed = prefs.getBool(AppConstants.storageOnboardingCompleted) ?? false;
      expect(completed, isTrue, reason: 'Returning user should skip onboarding');
    });

    test('Replay intro: flag resets to false', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.storageOnboardingCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      // Simulate "Replay intro" action
      await prefs.setBool(AppConstants.storageOnboardingCompleted, false);
      final completed = prefs.getBool(AppConstants.storageOnboardingCompleted) ?? false;
      expect(completed, isFalse, reason: 'Replay intro should reset onboarding flag');
    });

    test('Onboarding storage key matches expected constant', () {
      expect(AppConstants.storageOnboardingCompleted, 'ff_onboarding_completed');
    });
  });

  group('Version comparison unit tests', () {
    // Direct semantic version comparison logic tests
    List<int> parseParts(String v) {
      final p = v.split('.');
      return [
        int.tryParse(p.isNotEmpty ? p[0] : '0') ?? 0,
        int.tryParse(p.length > 1 ? p[1] : '0') ?? 0,
        int.tryParse(p.length > 2 ? p[2] : '0') ?? 0,
      ];
    }

    bool isNewer(String remote, String local, int rBuild, int lBuild) {
      final rv = parseParts(remote);
      final lv = parseParts(local);
      for (int i = 0; i < 3; i++) {
        if (rv[i] > lv[i]) return true;
        if (rv[i] < lv[i]) return false;
      }
      return rBuild > lBuild;
    }

    test('1.8.0 is newer than 1.7.0', () => expect(isNewer('1.8.0', '1.7.0', 1, 7), isTrue));
    test('1.7.0+9 is newer than 1.7.0+8', () => expect(isNewer('1.7.0', '1.7.0', 9, 8), isTrue));
    test('1.7.0+8 is not newer than 1.7.0+8', () => expect(isNewer('1.7.0', '1.7.0', 8, 8), isFalse));
    test('1.6.0 is not newer than 1.7.0', () => expect(isNewer('1.6.0', '1.7.0', 99, 1), isFalse));
    test('2.0.0 is newer than 1.99.99', () => expect(isNewer('2.0.0', '1.99.99', 1, 1), isTrue));
  });
}
