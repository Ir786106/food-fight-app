import 'package:flutter/services.dart';
import 'package:food_fight/screens/checkout/order_success_screen.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/constants/app_dimens.dart';
import 'package:food_fight/core/constants/app_colors.dart';
import 'package:food_fight/core/utils/app_insets.dart';
import 'package:food_fight/core/utils/app_snackbar.dart';
import 'package:food_fight/widgets/navigation/floating_nav_bar.dart';

void main() {
  setUpAll(() async {
    final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
    final fonts = Directory('${artifacts.path}/material_fonts');
    for (final entry in {'Roboto': 'roboto-regular.ttf', 'MaterialIcons': 'materialicons-regular.otf'}.entries) {
      final file = File('${fonts.path}/${entry.value}');
      if (await file.exists()) {
        final loader = FontLoader(entry.key)..addFont(file.readAsBytes().then(ByteData.sublistView));
        await loader.load();
      }
    }
  });
  for (final dark in [false, true]) {
    for (final inset in [24.0, 48.0]) {
      testWidgets('Global feedback clears nav: dark=$dark systemInset=$inset',
          (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final capture = GlobalKey();
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(fontFamily: 'Roboto',
                brightness: dark ? Brightness.dark : Brightness.light,
                colorSchemeSeed: AppColors.brandMaroon,
                useMaterial3: true),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    padding: EdgeInsets.only(top: 24, bottom: inset),
                    viewPadding: EdgeInsets.only(top: 24, bottom: inset),
                    textScaler: const TextScaler.linear(1.3)),
                child: child!),
            home: RepaintBoundary(
                key: capture,
                child: Scaffold(
                  appBar: AppBar(title: const Text('Food Fight')),
                  body: Builder(
                      builder: (context) => ListView(
                              padding: AppInsets.scrollPadding(context),
                              children: [
                                const Text('Global layout verification'),
                                FilledButton(
                                    onPressed: () => AppSnackbar.showSuccess(
                                        context, 'Added to cart',
                                        action: SnackBarAction(
                                            label: 'View', onPressed: () {})),
                                    child: const Text('Show feedback')),
                              ])),
                  bottomNavigationBar: FloatingNavBar(
                      currentIndex: 0,
                      onTabSelected: (_) {},
                      explicitChatUnreadCount: 3),
                ))));
        await tester.tap(find.text('Show feedback'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final nav = tester.getRect(find.byType(FloatingNavBar));
        final snack = tester.getRect(find.byType(SnackBar));
        expect(nav.height, AppDimens.navBarHeight + inset);
        expect(nav.bottom, 640);
        expect(snack.bottom, lessThanOrEqualTo(nav.top));
        expect(find.byType(FloatingNavBar), findsOneWidget);
        if (inset == 48) {
          await tester.runAsync(() async {
            final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory('artifacts/phase-a').create(recursive: true);
            await File('artifacts/phase-a/${dark ? 'dark' : 'light'}-360x640.png').writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
  testWidgets(
      'Insets include only visible overlays and hidden nav takes no space',
      (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(padding: EdgeInsets.only(bottom: 24)),
            child: Builder(builder: (context) {
              captured = context;
              return FloatingNavBar(
                  currentIndex: 0, onTabSelected: (_) {}, isVisible: false);
            }))));
    expect(AppInsets.bottomBarClearance(captured), 24 + AppDimens.space16);
    expect(AppInsets.bottomBarClearance(captured, hasCartPill: true),
        24 + AppDimens.space16 + AppDimens.cartPillHeight + AppDimens.space12);
    expect(find.byType(SafeArea), findsNothing);
  });
  testWidgets('System back on success clears checkout even without route data',
      (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
        MaterialApp(navigatorKey: nav, initialRoute: '/checkout', routes: {
      '/': (_) => const Scaffold(body: Text('Initial')),
      '/home': (_) => const Scaffold(body: Text('Home destination')),
      '/checkout': (_) => const Scaffold(body: Text('Checkout destination')),
      '/success': (_) => const OrderSuccessScreen(),
    }));
    nav.currentState!.pushNamed('/success');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Home destination'), findsOneWidget);
    expect(find.text('Checkout destination'), findsNothing);
    expect(nav.currentState!.canPop(), isFalse);
  });
}
