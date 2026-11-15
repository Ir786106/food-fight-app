import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/widgets/checkout/checkout_payment_section.dart';

void main() {
  testWidgets('checkout shows COD and exposes no card capture controls',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 300, child: CheckoutPaymentSection()),
      ),
    ));

    expect(find.text('Cash on Delivery'), findsOneWidget);
    expect(
        find.text('Online payment is currently unavailable.'), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
    expect(find.text('Scan Card'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Urdu checkout fits a narrow layout with larger text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ur'),
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.5)),
        child: child!,
      ),
      home: const Scaffold(body: CheckoutPaymentSection()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ڈیلیوری پر نقد ادائیگی'), findsOneWidget);
    expect(
        find.text('آن لائن ادائیگی فی الحال دستیاب نہیں ہے۔'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(CheckoutPaymentSection))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
