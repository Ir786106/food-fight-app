import '../../models/user_role.dart';

enum AppEdition {
  combined('Food Fight'),
  customer('Food Fight Customer'),
  rider('Food Fight Rider'),
  admin('Food Fight Admin');

  const AppEdition(this.title);
  final String title;

  bool get allowsCustomerRegistration =>
      this == AppEdition.combined || this == AppEdition.customer;

  bool allowsRole(UserRole role) => switch (this) {
        AppEdition.combined => true,
        AppEdition.customer => role == UserRole.customer,
        AppEdition.rider => role.isRider,
        AppEdition.admin => role.isAdminLevel,
      };

  bool allowsRoute(String route) {
    if (this == AppEdition.combined) return true;
    if (const {
      '/splash', '/login', '/forgot-password', '/reset-password',
      '/notifications', '/settings', '/edit-profile',
    }.contains(route)) {
      return true;
    }
    final adminRoute = route.startsWith('/admin/') || route.startsWith('/super-admin/');
    final riderRoute = route == '/rider' || route.startsWith('/rider/');
    return switch (this) {
      AppEdition.admin => adminRoute,
      AppEdition.rider => riderRoute,
      AppEdition.customer => !adminRoute && !riderRoute,
      AppEdition.combined => true,
    };
  }
}
