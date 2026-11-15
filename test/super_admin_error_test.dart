import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/errors/platform_operation_error.dart';
import 'package:food_fight/routes/app_routes.dart';
import 'package:food_fight/screens/admin/chats/admin_chats_screen.dart';
import 'package:food_fight/screens/admin/deals/manage_deals_screen.dart';
import 'package:food_fight/screens/admin/riders/manage_riders_screen.dart';
import 'package:food_fight/widgets/common/error_view.dart';

void main() {
  testWidgets('platform routes use the Super Admin guard and platform scope',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox).first);
    Widget guardedChild(String path) =>
        (AppRoutes.routes[path]!(context) as SuperAdminRouteGuard).child;

    expect(
        (guardedChild('/super-admin/chats') as AdminChatsScreen).platformWide,
        isTrue);
    expect(
        (guardedChild('/super-admin/deals') as ManageDealsScreen).platformWide,
        isTrue);
    expect(
        (guardedChild('/super-admin/riders') as ManageRidersScreen)
            .platformWide,
        isTrue);
  });

  test('callable errors use actionable copy without internal details', () {
    final unavailable = platformOperationError(
      FirebaseFunctionsException(code: 'not-found', message: 'internal stack'),
      fallback: 'Try again.',
    );
    expect(unavailable, contains('unavailable'));
    expect(unavailable, isNot(contains('internal stack')));
    expect(
      platformOperationError(
        FirebaseFunctionsException(
            code: 'permission-denied', message: 'denied'),
        fallback: 'Try again.',
      ),
      contains('permission'),
    );
    expect(
        platformOperationError(StateError('internal'), fallback: 'Try again.'),
        'Try again.');
  });

  testWidgets('dark error view scrolls and can retry on a small display',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 260,
            height: 160,
            child: ErrorView(
              message: 'The platform service is unavailable. Please try again.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      ),
    ));
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try Again'));
    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
  });
}
