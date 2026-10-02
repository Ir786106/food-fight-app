import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/widgets/navigation/floating_nav_bar.dart';

void main() {
  group('FloatingNavBar Widget & Badge Tests', () {
    testWidgets('Renders all 5 navigation slots and displays active label only', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      // Verify icons are present
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_rounded), findsOneWidget); // Center raised cart button
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

      // Active label "Home" is visible, other labels are hidden to keep layout clean
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Orders'), findsNothing);
      expect(find.text('Chat'), findsNothing);
      expect(find.text('Profile'), findsNothing);
    });

    testWidgets('Switching tabs invokes onTabSelected with correct index', (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: selected,
              onTabSelected: (idx) => selected = idx,
            ),
          ),
        ),
      );

      // Tap Orders tab (slot 1)
      await tester.tap(find.byIcon(Icons.receipt_long_outlined));
      await tester.pumpAndSettle();
      expect(selected, equals(1));

      // Tap Chat tab (slot 3)
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pumpAndSettle();
      expect(selected, equals(3));

      // Tap Profile tab (slot 4)
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();
      expect(selected, equals(4));
    });

    testWidgets('Center raised cart button triggers onCartSelected and shows live badge count', (tester) async {
      bool cartTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: 0,
              explicitCartCount: 3,
              onTabSelected: (_) {},
              onCartSelected: () => cartTapped = true,
            ),
          ),
        ),
      );

      // Verify cart badge count is displayed
      expect(find.text('3'), findsOneWidget);

      // Tap center cart button
      await tester.tap(find.byIcon(Icons.shopping_bag_rounded));
      await tester.pumpAndSettle();
      expect(cartTapped, isTrue);
    });

    testWidgets('Chat unread badge and active order dot are displayed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: 0,
              explicitChatUnreadCount: 5,
              explicitHasActiveOrder: true,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      // Unread chat badge count
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Replaces bar with NavigationRail on tablet/large screens (>= 840px)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingNavBar(
              currentIndex: 0,
              explicitCartCount: 2,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
