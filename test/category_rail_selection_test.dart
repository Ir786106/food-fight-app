import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/models/category_model.dart';
import 'package:food_fight/widgets/home/category_rail.dart';

void main() {
  group('CategoryRail Widget Tests', () {
    final testCategories = [
      CategoryModel(
        id: 'cat-1',
        name: 'Burgers',
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: 'cat-2',
        name: 'Pizza',
        order: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CategoryModel(
        id: 'cat-3',
        name: 'Drinks',
        order: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    testWidgets('Renders top menu/search buttons, Firestore categories, and bottom filter button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryRail(
              categories: testCategories,
              selectedCategory: 'All',
              onCategorySelected: (_) {},
              onMenuTap: () {},
              onSearchTap: () {},
              onFilterTap: () {},
            ),
          ),
        ),
      );

      // Verify top actions
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // Verify categories
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Burgers'), findsOneWidget);
      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('Drinks'), findsOneWidget);

      // Verify bottom filter action
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('Tapping category button invokes onCategorySelected callback', (tester) async {
      String selected = 'All';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryRail(
              categories: testCategories,
              selectedCategory: selected,
              onCategorySelected: (cat) => selected = cat,
              onMenuTap: () {},
              onSearchTap: () {},
              onFilterTap: () {},
            ),
          ),
        ),
      );

      // Tap Pizza category
      await tester.tap(find.text('Pizza'));
      await tester.pumpAndSettle();
      expect(selected, equals('Pizza'));

      // Tap Burgers category
      await tester.tap(find.text('Burgers'));
      await tester.pumpAndSettle();
      expect(selected, equals('Burgers'));
    });

    testWidgets('Menu and filter buttons invoke corresponding callbacks', (tester) async {
      bool menuTapped = false;
      bool filterTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryRail(
              categories: testCategories,
              selectedCategory: 'All',
              onCategorySelected: (_) {},
              onMenuTap: () => menuTapped = true,
              onSearchTap: () {},
              onFilterTap: () => filterTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      expect(menuTapped, isTrue);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      expect(filterTapped, isTrue);
    });
  });
}
