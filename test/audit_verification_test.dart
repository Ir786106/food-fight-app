import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/models/delivery_area_model.dart';
import 'package:food_fight/models/admin/admin_account_model.dart';
import 'package:food_fight/models/category_model.dart';
import 'package:food_fight/models/menu_item_model.dart';

void main() {
  group('Audit Verification: Order Status & Serialization', () {
    test('OrderStatus parses camelCase and space-separated values accurately', () {
      final jsonPickedUp = {
        'id': 'ord_1',
        'orderNumber': 'FF-1001',
        'items': [],
        'subtotal': 500.0,
        'total': 600.0,
        'status': 'pickedUp',
        'paymentMethod': 'Cash on Delivery',
        'paymentStatus': 'pending',
        'deliveryAddress': 'Model Town, Block A',
        'customerId': 'cust_1',
        'restaurantName': 'Food Fight',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      final orderPickedUp = OrderModel.fromJson(jsonPickedUp);
      expect(orderPickedUp.status, OrderStatus.pickedUp);
      expect(orderPickedUp.status.displayName, 'Picked Up');
      expect(orderPickedUp.statusLabel, 'Picked Up');

      final jsonOutForDelivery = Map<String, dynamic>.from(jsonPickedUp);
      jsonOutForDelivery['status'] = 'outForDelivery';
      final orderOutForDelivery = OrderModel.fromJson(jsonOutForDelivery);
      expect(orderOutForDelivery.status, OrderStatus.outForDelivery);
      expect(orderOutForDelivery.status.displayName, 'Out for Delivery');

      // Test space-separated fallback
      final jsonOutForDeliverySpaced = Map<String, dynamic>.from(jsonPickedUp);
      jsonOutForDeliverySpaced['status'] = 'out for delivery';
      final orderSpaced = OrderModel.fromJson(jsonOutForDeliverySpaced);
      expect(orderSpaced.status, OrderStatus.outForDelivery);
    });

    test('All OrderStatus enum values have non-empty displayNames and match statusLabels', () {
      for (final status in OrderStatus.values) {
        expect(status.displayName.isNotEmpty, isTrue);
        final order = OrderModel(
          id: 'test',
          orderNumber: 'FF-0001',
          items: const [],
          subtotal: 100,
          total: 100,
          paymentMethod: 'COD',
          deliveryAddress: 'Test',
          customerId: 'cust',
          restaurantName: 'Food Fight',
          status: status,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(order.statusLabel, status.displayName);
      }
    });
  });

  group('Audit Verification: DeliveryAreaModel Equality for Dropdowns', () {
    test('Two DeliveryArea instances with matching id are equal and have same hashCode', () {
      final area1 = DeliveryAreaModel(
        id: 'area_1',
        name: 'Model Town',
        deliveryCharge: 150.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final area2 = DeliveryAreaModel(
        id: 'area_1',
        name: 'Model Town (Updated Name)',
        deliveryCharge: 180.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final area3 = DeliveryAreaModel(
        id: 'area_2',
        name: 'Circular Road',
        deliveryCharge: 120.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(area1 == area2, isTrue);
      expect(area1.hashCode, area2.hashCode);
      expect(area1 == area3, isFalse);

      final list = [area1, area3];
      expect(list.contains(area2), isTrue);
    });
  });

  group('Audit Verification: AdminAccountModel isActive and status Consistency', () {
    test('AdminAccountModel.toJson emits isActive 1 when active', () {
      final admin = AdminAccountModel(
        id: 'adm_1',
        name: 'Manager',
        email: 'manager@foodfight.pk',
        phone: '03001234567',
        role: 'admin',
        status: 'active',
      );

      final json = admin.toJson();
      expect(json['status'], 'active');
      expect(json['isActive'], 1);
    });

    test('AdminAccountModel.toJson emits isActive 0 when suspended or deactivated', () {
      final adminSuspended = AdminAccountModel(
        id: 'adm_2',
        name: 'Suspended Staff',
        email: 'staff@foodfight.pk',
        phone: '03001234568',
        role: 'staff',
        status: 'suspended',
      );

      expect(adminSuspended.toJson()['isActive'], 0);

      final adminDeactivated = AdminAccountModel(
        id: 'adm_3',
        name: 'Ex Staff',
        email: 'ex@foodfight.pk',
        phone: '03001234569',
        role: 'staff',
        status: 'deactivated',
      );

      expect(adminDeactivated.toJson()['isActive'], 0);
    });

    test('AdminAccountModel.fromJson handles both integer 1/0 and boolean true/false', () {
      final jsonWithInt = {
        'id': 'adm_4',
        'name': 'Test',
        'email': 'test@foodfight.pk',
        'phone': '123',
        'role': 'admin',
        'isActive': 1,
      };
      final adm1 = AdminAccountModel.fromJson(jsonWithInt);
      expect(adm1.isActive, isTrue);
      expect(adm1.status, 'active');

      final jsonWithBool = {
        'id': 'adm_5',
        'name': 'Test 2',
        'email': 'test2@foodfight.pk',
        'phone': '123',
        'role': 'admin',
        'isActive': false,
      };
      final adm2 = AdminAccountModel.fromJson(jsonWithBool);
      expect(adm2.isActive, isFalse);
      expect(adm2.status, 'suspended');
    });
  });

  group('Audit Verification: In-Memory Active Filtering across Models', () {
    test('CategoryModel correctly parses both int 1 and boolean true', () {
      final cat1 = CategoryModel.fromJson({
        'id': 'cat_1',
        'name': 'Burgers',
        'isActive': 1,
        'order': 1,
        'createdAt': 0,
        'updatedAt': 0,
      });
      final cat2 = CategoryModel.fromJson({
        'id': 'cat_2',
        'name': 'Archived Pizza',
        'isActive': 0,
        'order': 2,
        'createdAt': 0,
        'updatedAt': 0,
      });
      final cat3 = CategoryModel.fromJson({
        'id': 'cat_3',
        'name': 'Legacy Deals',
        'isActive': true,
        'order': 3,
        'createdAt': 0,
        'updatedAt': 0,
      });

      final categories = [cat1, cat2, cat3];
      final activeCategories = categories.where((c) => c.isActive).toList();

      expect(activeCategories.length, 2);
      expect(activeCategories.map((c) => c.id), containsAll(['cat_1', 'cat_3']));
    });

    test('MenuItemModel correctly parses both int 1 and boolean true', () {
      final item1 = MenuItemModel.fromJson({
        'id': 'item_1',
        'name': 'Zinger Burger',
        'price': 450.0,
        'categoryId': 'cat_1',
        'isActive': 1,
        'createdAt': 0,
        'updatedAt': 0,
      });
      final item2 = MenuItemModel.fromJson({
        'id': 'item_2',
        'name': 'Old Inactive Drink',
        'price': 100.0,
        'categoryId': 'cat_1',
        'isActive': false,
        'createdAt': 0,
        'updatedAt': 0,
      });

      final items = [item1, item2];
      final activeItems = items.where((i) => i.isActive).toList();

      expect(activeItems.length, 1);
      expect(activeItems.first.name, 'Zinger Burger');
    });
  });
}
