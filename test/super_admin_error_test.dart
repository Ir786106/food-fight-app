import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/errors/platform_operation_error.dart';
import 'package:food_fight/widgets/common/error_view.dart';

void main() {
  test('callable errors use actionable copy without internal details', () {
    final unavailable = platformOperationError(
      FirebaseFunctionsException(code: 'not-found', message: 'internal stack'),
      fallback: 'Try again.',
    );
    expect(unavailable, contains('unavailable'));
    expect(unavailable, isNot(contains('internal stack')));
    expect(
      platformOperationError(
        FirebaseFunctionsException(code: 'permission-denied', message: 'denied'),
        fallback: 'Try again.',
      ),
      contains('permission'),
    );
    expect(platformOperationError(StateError('internal'), fallback: 'Try again.'),
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
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try Again'));
    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
  });
}
