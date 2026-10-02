import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/widgets/common/floating_notch_nav_bar.dart';

void main() {
  group('FloatingNotchNavBar Widget Tests', () {
    const testTabs = [
      NavTabItem(
        activeIcon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined,
        label: 'Home',
        semanticLabel: 'Home Tab',
      ),
      NavTabItem(
        activeIcon: Icons.receipt_long_rounded,
        inactiveIcon: Icons.receipt_long_outlined,
        label: 'Orders',
        semanticLabel: 'Orders Tab',
      ),
      NavTabItem(
        activeIcon: Icons.favorite_rounded,
        inactiveIcon: Icons.favorite_border_rounded,
        label: 'My List',
        semanticLabel: 'My Favorites Tab',
      ),
      NavTabItem(
        activeIcon: Icons.person_rounded,
        inactiveIcon: Icons.person_outline_rounded,
        label: 'Profile',
        semanticLabel: 'Profile Tab',
      ),
    ];

    testWidgets('Renders all 4 tab labels and icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNotchNavBar(
              currentIndex: 0,
              onTabSelected: (_) {},
              onCenterAction: () {},
              tabs: testTabs,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('My List'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Tab switching fires callback with correct index', (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNotchNavBar(
              currentIndex: selectedIndex,
              onTabSelected: (idx) => selectedIndex = idx,
              onCenterAction: () {},
              tabs: testTabs,
            ),
          ),
        ),
      );

      // Tap Orders tab (index 1)
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      expect(selectedIndex, equals(1));

      // Tap Profile tab (index 3)
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(selectedIndex, equals(3));
    });

    testWidgets('Center button shows live badge count and triggers center action', (WidgetTester tester) async {
      bool centerTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNotchNavBar(
              currentIndex: 0,
              centerBadgeCount: 4,
              onTabSelected: (_) {},
              onCenterAction: () => centerTapped = true,
              tabs: testTabs,
            ),
          ),
        ),
      );

      // Verify badge count
      expect(find.text('4'), findsOneWidget);

      // Tap center shopping bag button
      await tester.tap(find.byIcon(Icons.shopping_bag_rounded));
      await tester.pumpAndSettle();

      expect(centerTapped, isTrue);
    });
  });
}
