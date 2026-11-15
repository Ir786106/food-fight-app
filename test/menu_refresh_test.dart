import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/providers/menu_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('admin refresh retains branch and excludes legacy items', () async {
    final provider = MenuProvider(
      fetchMenu: ({categoryId, branchId, required includeLegacy}) async {
        expect(branchId, 'branch-a');
        expect(includeLegacy, isFalse);
        return [MenuItemModel.fromJson({'id': 'first'})];
      },
    );
    addTearDown(provider.dispose);
    await provider.fetchMenuItems(branchId: 'branch-a', includeLegacy: false);
    expect(provider.currentBranchId, 'branch-a');
    expect(provider.menuItems.single.id, 'first');
  });

  test('late refresh cannot replace newer results or hide a read error', () async {
    final older = Completer<List<MenuItemModel>>();
    var calls = 0;
    final provider = MenuProvider(
      fetchMenu: ({categoryId, branchId, required includeLegacy}) {
        if (++calls == 1) return older.future;
        return Future.error(StateError('internal details'));
      },
    );
    addTearDown(provider.dispose);
    final pending = provider.fetchMenuItems(branchId: 'branch-a');
    await provider.fetchMenuItems(branchId: 'branch-a');
    older.complete([MenuItemModel.fromJson({'id': 'stale'})]);
    await pending;
    expect(provider.menuItems, isEmpty);
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, 'Unable to load menu items. Please try again.');
  });
}
