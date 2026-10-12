import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_fight/services/firebase/firebase_auth_service.dart';

void main() {
  group('Splash Routing Decision Logic', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    String resolveRoleRoute(String? role) {
      final normalized = (role ?? '').trim().toLowerCase();
      if (normalized == 'superadmin' || normalized == 'super_admin') {
        return '/super-admin/dashboard';
      } else if (normalized == 'admin') {
        return '/admin/dashboard';
      } else if (normalized == 'rider') {
        return '/rider/dashboard';
      } else {
        return '/home';
      }
    }

    String decideRoute({
      required bool isAuthenticated,
      required bool onboardingCompleted,
      String? cachedRole,
      bool isNetworkTimeout = false,
    }) {
      if (!isAuthenticated) {
        return onboardingCompleted ? '/login' : '/onboarding';
      }

      // If user is authenticated, network timeout must NEVER redirect to /login
      if (isNetworkTimeout) {
        return resolveRoleRoute(cachedRole ?? 'customer');
      }

      return resolveRoleRoute(cachedRole);
    }

    test('Logged out fresh install routes to /onboarding', () async {
      final route = decideRoute(
        isAuthenticated: false,
        onboardingCompleted: false,
      );
      expect(route, equals('/onboarding'));
    });

    test('Logged out returning install routes to /login', () async {
      final route = decideRoute(
        isAuthenticated: false,
        onboardingCompleted: true,
      );
      expect(route, equals('/login'));
    });

    test('Logged in customer routes directly to /home', () {
      final route = decideRoute(
        isAuthenticated: true,
        onboardingCompleted: true,
        cachedRole: 'customer',
      );
      expect(route, equals('/home'));
    });

    test('Logged in admin routes to /admin/dashboard', () {
      final route = decideRoute(
        isAuthenticated: true,
        onboardingCompleted: true,
        cachedRole: 'admin',
      );
      expect(route, equals('/admin/dashboard'));
    });

    test('Logged in superadmin routes to /super-admin/dashboard', () {
      final route = decideRoute(
        isAuthenticated: true,
        onboardingCompleted: true,
        cachedRole: 'super_admin',
      );
      expect(route, equals('/super-admin/dashboard'));
    });

    test('Logged in rider routes to /rider/dashboard', () {
      final route = decideRoute(
        isAuthenticated: true,
        onboardingCompleted: true,
        cachedRole: 'rider',
      );
      expect(route, equals('/rider/dashboard'));
    });

    test('Offline / network timeout: Logged-in user stays logged in and never sent to /login', () {
      final route = decideRoute(
        isAuthenticated: true,
        onboardingCompleted: true,
        cachedRole: 'admin',
        isNetworkTimeout: true,
      );
      expect(route, equals('/admin/dashboard'));
      expect(route, isNot(equals('/login')));
    });

    test('Offline with unknown role defaults to safe storefront /home and never /login', () {
      final route = decideRoute(
        isAuthenticated: true,
        onboardingCompleted: true,
        cachedRole: null,
        isNetworkTimeout: true,
      );
      expect(route, equals('/home'));
      expect(route, isNot(equals('/login')));
    });

    test('Role caching in SharedPreferences preserves role across offline restarts', () async {
      SharedPreferences.setMockInitialValues({});
      await FirebaseAuthService.cacheRoleLocally('user_xyz_123', 'admin');

      final cachedRole = await FirebaseAuthService.getCachedUserRole('user_xyz_123');
      expect(cachedRole, equals('admin'));
    });
  });
}
