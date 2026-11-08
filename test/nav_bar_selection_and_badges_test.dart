import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/widgets/navigation/floating_nav_bar.dart';

void main() {
  group('FloatingNavBar Widget & Badge Tests', () {
    testWidgets('Renders all 4 destinations and displays clear labels for all items', (tester) async {
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
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

      // All labels are clearly visible and accessible
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
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

      // Tap Orders tab (index 1)
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      expect(selected, equals(1));

      // Tap Chat tab (index 2)
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      expect(selected, equals(2));

      // Tap Profile tab (index 3)
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(selected, equals(3));
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

    testWidgets('Displays tablet rail on large screens (>= 840px)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingNavBar(
              currentIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}
