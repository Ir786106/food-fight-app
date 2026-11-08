import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/screens/auth/phone_sign_in_dialog.dart';

void main() {
  test('Pakistani mobile formats normalize to the same Firebase number', () {
    for (final input in [
      '0300 1234567',
      '+92 (300) 123-4567',
      '00923001234567',
      '3001234567',
    ]) {
      expect(PhoneSignInDialog.pakistaniMobile(input), '+923001234567');
    }
    for (final input in ['', '02112345678', '+14155552671', '0300123456']) {
      expect(PhoneSignInDialog.pakistaniMobile(input), isNull);
    }
  });

  testWidgets('invalid mobile input is rejected before sending an SMS',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PhoneSignInDialog()));
    await tester.enterText(find.byType(TextField), '12345');
    await tester.tap(find.text('Send code'));
    await tester.pump();
    expect(find.text('Enter a valid Pakistani mobile number.'), findsOneWidget);
    expect(find.text('Verify'), findsNothing);
  });
}
