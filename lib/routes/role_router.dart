import 'package:flutter/widgets.dart';
import '../models/user_model.dart';

/// Centralized role-based routing authority for Food Fight.
/// Used by login, splash screen, route guards, and "go home" actions.
class RoleRouter {
  static const String superAdminHome = '/super-admin/dashboard';
  static const String adminHome = '/admin/dashboard';
  static const String riderHome = '/rider/dashboard';
  static const String customerHome = '/home';
  static const String loginRoute = '/login';

  /// Resolves the canonical home route for a [UserModel].
  static String homeRouteFor(UserModel? user) {
    if (user == null) return customerHome;
    return homeRouteForRole(user.role);
  }

  /// Resolves the canonical home route from any role representation (String, UserRole, etc.)
  static String homeRouteForRole(dynamic role) {
    final parsed = role is UserRole ? role : UserRole.fromString(role);
    switch (parsed) {
      case UserRole.superAdmin:
        return superAdminHome;
      case UserRole.admin:
      case UserRole.subAdmin:
      case UserRole.staff:
        return adminHome;
      case UserRole.rider:
        return riderHome;
      case UserRole.customer:
      case UserRole.unknown:
        return customerHome;
    }
  }

  /// Navigate the user to their designated dashboard, replacing stack by default.
  static void navigateHome(
    BuildContext context,
    UserModel? user, {
    bool clearStack = true,
  }) {
    final route = homeRouteFor(user);
    if (clearStack) {
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil(route, (r) => false);
    } else {
      Navigator.of(context).pushNamed(route);
    }
  }
}
