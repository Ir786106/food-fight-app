import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/widgets/navigation/floating_nav_bar.dart';

void main() {
  group('FloatingNavBar Widget Tests', () {
    testWidgets('Renders all 4 tab destinations (Home, Orders, Chat, Profile)', (WidgetTester tester) async {
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

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Tab switching fires callback with correct index', (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: selectedIndex,
              onTabSelected: (idx) => selectedIndex = idx,
            ),
          ),
        ),
      );

      // Tap Orders tab (index 1)
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      expect(selectedIndex, equals(1));

      // Tap Chat tab (index 2)
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      expect(selectedIndex, equals(2));

      // Tap Profile tab (index 3)
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(selectedIndex, equals(3));
    });

    testWidgets('Shows chat unread badge count when > 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: 0,
              explicitChatUnreadCount: 5,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      // Verify unread badge count
      expect(find.text('5'), findsOneWidget);
    });
  });
}
