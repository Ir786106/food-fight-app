import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/core/errors/app_exception.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/constants/firestore_fields.dart';

/// Firebase Firestore Service Implementation
class FirebaseFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Common helpers
  CollectionReference get _usersCollection => _firestore.collection(FirestoreCollections.users);
  CollectionReference get _categoriesCollection => _firestore.collection(FirestoreCollections.categories);
  CollectionReference get _menuItemsCollection => _firestore.collection(FirestoreCollections.menuItems);
  CollectionReference get _ordersCollection => _firestore.collection(FirestoreCollections.orders);
  CollectionReference get _deliveryAreasCollection => _firestore.collection(FirestoreCollections.deliveryAreas);

  // User operations
  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      await _usersCollection.doc(userData[FirestoreFields.uid]).set(userData);
      AppLogger.info('User created: ${userData[FirestoreFields.fieldEmail]}', tag: 'FirebaseFirestoreService');
    } catch (e) {
      AppLogger.error('Error creating user: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to create user');
    }
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting user: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to get user');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _usersCollection.doc(userId).update(userData);
      AppLogger.info('User updated: $userId', tag: 'FirebaseFirestoreService');
    } catch (e) {
      AppLogger.error('Error updating user: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to update user');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
      AppLogger.info('User deleted: $userId', tag: 'FirebaseFirestoreService');
    } catch (e) {
      AppLogger.error('Error deleting user: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to delete user');
    }
  }

  // Category operations
  Future<DocumentReference?> createCategory(Map<String, dynamic> categoryData) async {
    try {
      final docRef = await _categoriesCollection.add(categoryData);
      AppLogger.info('Category created: ${categoryData[FirestoreFields.fieldCategoryName]}', tag: 'FirebaseFirestoreService');
      return docRef;
    } catch (e) {
      AppLogger.error('Error creating category: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to create category');
    }
  }

  Future<void> updateCategory(String categoryId, Map<String, dynamic> categoryData) async {
    try {
      await _categoriesCollection.doc(categoryId).update(categoryData);
      AppLogger.info('Category updated: $categoryId', tag: 'FirebaseFirestoreService');
    } catch (e) {
      AppLogger.error('Error updating category: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to update category');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoriesCollection.doc(categoryId).delete();
      AppLogger.info('Category deleted: $categoryId', tag: 'FirebaseFirestoreService');
    } catch (e) {
      AppLogger.error('Error deleting category: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to delete category');
    }
  }

  // Order operations
  Future<DocumentReference?> createOrder(Map<String, dynamic> orderData) async {
    try {
      final docRef = await _ordersCollection.add(orderData);
      AppLogger.info('Order created: ${orderData[FirestoreFields.fieldOrderNumber]}', tag: 'FirebaseFirestoreService');
      return docRef;
    } catch (e) {
      AppLogger.error('Error creating order: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to create order');
    }
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> orderData) async {
    try {
      await _ordersCollection.doc(orderId).update(orderData);
      AppLogger.info('Order updated: $orderId', tag: 'FirebaseFirestoreService');
    } catch (e) {
      AppLogger.error('Error updating order: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to update order');
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _ordersCollection.doc(orderId).delete();
      AppLogger.info('Order deleted: $orderId', tag: 'FirebaseFirestoreService');
    } catch (e) {
      AppLogger.error('Error deleting order: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to delete order');
    }
  }

  // Delivery area operations
  Future<DocumentReference?> createDeliveryArea(Map<String, dynamic> areaData) async {
    try {
      final docRef = await _deliveryAreasCollection.add(areaData);
      AppLogger.info('Delivery area created: ${areaData[FirestoreFields.fieldAreaName]}', tag: 'FirebaseFirestoreService');
      return docRef;
    } catch (e) {
      AppLogger.error('Error creating delivery area: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to create delivery area');
    }
  }

  Future<void> updateDeliveryArea(String areaId, Map<String, dynamic> areaData) async {
    try {
      await _deliveryAreasCollection.doc(areaId).update(areaData);
      AppLogger.info('Delivery area updated: $areaId', tag: 'FirebaseFirestoreService');
    } catch (e) {
      AppLogger.error('Error updating delivery area: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to update delivery area');
    }
  }

  Future<void> deleteDeliveryArea(String areaId) async {
    try {
      await _deliveryAreasCollection.doc(areaId).delete();
      AppLogger.info('Delivery area deleted: $areaId', tag: 'FirebaseFirestoreService');
    } catch (e) {
      AppLogger.error('Error deleting delivery area: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to delete delivery area');
    }
  }

  // Menu item operations
  Future<DocumentReference?> createMenuItem(Map<String, dynamic> menuItemData) async {
    try {
      final docRef = await _menuItemsCollection.add(menuItemData);
      AppLogger.info('Menu item created: ${menuItemData[FirestoreFields.fieldMenuItemName]}', tag: 'FirebaseFirestoreService');
      return docRef;
    } catch (e) {
      AppLogger.error('Error creating menu item: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to create menu item');
    }
  }

  Future<void> updateMenuItem(String itemId, Map<String, dynamic> menuItemData) async {
    try {
      await _menuItemsCollection.doc(itemId).update(menuItemData);
      AppLogger.info('Menu item updated: $itemId', tag: 'FirebaseFirestoreService');
    } catch (e) {
      AppLogger.error('Error updating menu item: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to update menu item');
    }
  }

  Future<void> deleteMenuItem(String itemId) async {
    try {
      await _menuItemsCollection.doc(itemId).delete();
      AppLogger.info('Menu item deleted: $itemId', tag: 'FirebaseFirestoreService');
    } catch (e) {
      AppLogger.error('Error deleting menu item: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to delete menu item');
    }
  }

  // Query helpers
  Future<QuerySnapshot> getOrdersByUser(String userId) async {
    try {
      return await _ordersCollection
          .where(FirestoreFields.fieldUid, isEqualTo: userId)
          .orderBy(FirestoreFields.fieldCreatedAt, descending: true)
          .get();
    } catch (e) {
      AppLogger.error('Error getting orders: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to get orders');
    }
  }

  Future<QuerySnapshot> getOrdersByStatus(String userId, String status) async {
    try {
      return await _ordersCollection
          .where(FirestoreFields.fieldUid, isEqualTo: userId)
          .where(FirestoreFields.fieldStatus, isEqualTo: status)
          .orderBy(FirestoreFields.fieldCreatedAt, descending: true)
          .get();
    } catch (e) {
      AppLogger.error('Error getting orders by status: $e', tag: 'FirebaseFirestoreService');
      throw AppException(message: 'Failed to get orders');
    }
  }

  // Stream helpers
  Stream<DocumentSnapshot> listenToOrder(String orderId) {
    return _ordersCollection.doc(orderId).snapshots();
  }

  Stream<QuerySnapshot> listenToOrdersByUser(String userId) {
    return _ordersCollection
        .where(FirestoreFields.fieldUid, isEqualTo: userId)
        .orderBy(FirestoreFields.fieldCreatedAt, descending: true)
        .snapshots();
  }
}
