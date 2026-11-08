import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/config/app_edition.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/routes/app_routes.dart';
import 'package:food_fight/routes/role_router.dart';
import 'package:food_fight/services/firebase/firebase_auth_service.dart';

class _WrongEditionAuth extends FirebaseAuthService {
  _WrongEditionAuth(this.role);
  final UserRole role;
  bool signedOut = false;
  bool? usedCache;
  bool verifiedProfileRead = false;

  UserModel get user => UserModel(
        id: 'test-user',
        name: 'Test',
        email: '',
        phone: '',
        role: role.firestoreValue,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  @override
  Future<UserModel?> signIn({
    required String email,
    required String password,
    bool allowCachedRole = true,
  }) async {
    usedCache = allowCachedRole;
    return user;
  }

  @override
  Future<UserModel?> getVerifiedCurrentUser() async {
    verifiedProfileRead = true;
    return user;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each edition exposes its own routes and appropriate account roles', () {
    final customer = AppRoutes.routesFor(AppEdition.customer);
    final rider = AppRoutes.routesFor(AppEdition.rider);
    final admin = AppRoutes.routesFor(AppEdition.admin);
    expect(customer.keys, contains('/signup'));
    expect(customer.keys, contains(RoleRouter.customerHome));
    expect(customer.keys, isNot(contains(RoleRouter.riderHome)));
    expect(customer.keys, isNot(contains(RoleRouter.adminHome)));
    expect(rider.keys, contains(RoleRouter.riderHome));
    expect(rider.keys, isNot(contains('/signup')));
    expect(rider.keys, isNot(contains(RoleRouter.adminHome)));
    expect(admin.keys, contains(RoleRouter.adminHome));
    expect(admin.keys, contains(RoleRouter.superAdminHome));
    expect(admin.keys, isNot(contains(RoleRouter.customerHome)));
    expect(admin.keys, isNot(contains(RoleRouter.riderHome)));

    for (final role in UserRole.values.where((role) => role != UserRole.unknown)) {
      final allowed = AppEdition.values.where((edition) =>
          edition != AppEdition.combined && edition.allowsRole(role));
      expect(allowed, hasLength(1));
      expect(AppRoutes.routesFor(allowed.single).keys, contains(RoleRouter.homeRouteForRole(role)));
    }
  });

  test('wrong app password sign-in is rejected and signs out of Firebase', () async {
    final service = _WrongEditionAuth(UserRole.rider);
    final auth = AuthProvider(edition: AppEdition.admin, authService: service);
    expect(await auth.signIn(email: 'rider@example.test', password: 'example'), isFalse);
    expect(service.usedCache, isFalse);
    expect(service.signedOut, isTrue);
    expect(auth.currentUser, isNull);
    expect(auth.errorMessage, contains('Food Fight Admin'));
    auth.dispose();
  });

  test('restoring a session verifies the profile and rejects a mismatched role', () async {
    final service = _WrongEditionAuth(UserRole.admin);
    final auth = AuthProvider(edition: AppEdition.rider, authService: service);
    await auth.init();
    expect(service.verifiedProfileRead, isTrue);
    expect(service.signedOut, isTrue);
    expect(auth.currentUser, isNull);
    auth.dispose();
  });
}
