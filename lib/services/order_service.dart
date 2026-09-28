import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/models/notification_model.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'notification_service.dart';
import 'branch_service.dart';

/// Order Service for Customer ordering and Admin order management
class OrderService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection(FirestoreCollections.orders);

  /// Generate human-readable order number like "FF-4821"
  static String generateOrderNumber() {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    return 'FF-$number';
  }

  /// Place a new order
  static Future<String> placeOrder(OrderModel order) async {
    final docRef = _collection.doc();
    final data = order.toJson();
    data['id'] = docRef.id;
    if (order.orderNumber.isEmpty) {
      data['orderNumber'] = generateOrderNumber();
    }
    await docRef.set(data);
    AppLogger.info('Order placed: ${data['orderNumber']} (${docRef.id})', tag: 'OrderService');

    // Automatically update branch financial metrics
    if (order.branchId != null && order.branchId!.isNotEmpty) {
      await BranchService.recordOrderFinancials(order.branchId!, order.total);
    }

    // Create real notification for customer
    if (order.customerId.isNotEmpty) {
      try {
        final notifService = NotificationService();
        await notifService.createNotification(NotificationModel(
          id: '',
          userId: order.customerId,
          title: 'Order Placed! 🥊',
          message: 'Your order #${data['orderNumber']} has been received and sent to the kitchen.',
          type: 'order',
          referenceId: docRef.id,
          createdAt: DateTime.now(),
        ));
      } catch (e) {
        AppLogger.warn('Could not emit order notification: $e', tag: 'OrderService');
      }
    }

    return docRef.id;
  }

  /// Watch orders for a specific customer in real-time
  static Stream<List<OrderModel>> watchCustomerOrders(String customerId) {
    return _collection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return OrderModel.fromJson(data);
      }).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Watch a single order in real-time (for order tracking)
  static Stream<OrderModel?> watchOrder(String orderId) {
    return _collection.doc(orderId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return OrderModel.fromJson(data);
    });
  }

  /// Watch all orders (Admin panel), optionally filtered by status and branchId
  static Stream<List<OrderModel>> watchAllOrders({String? status, String? branchId}) {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      var orders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return OrderModel.fromJson(data);
      }).toList();

      if (branchId != null && branchId.isNotEmpty && branchId.toLowerCase() != 'all') {
        orders = orders.where((o) => o.branchId == branchId).toList();
      }

      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        final s = status.toLowerCase().replaceAll(' ', '');
        orders = orders.where((o) =>
            o.status.name.toLowerCase() == s ||
            o.status.displayName.toLowerCase().replaceAll(' ', '') == s).toList();
      }

      return orders;
    });
  }

  /// Update order status (Advance status or cancel)
  static Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? cancellationReason,
  }) async {
    final Map<String, dynamic> updates = {
      'status': newStatus.name,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    if (cancellationReason != null && cancellationReason.isNotEmpty) {
      updates['cancellationReason'] = cancellationReason;
    }

    await _collection.doc(orderId).update(updates);
    AppLogger.info('Updated order $orderId to ${newStatus.name}', tag: 'OrderService');

    // Emit live status notification to the customer
    try {
      final order = await getOrder(orderId);
      if (order != null && order.customerId.isNotEmpty) {
        await NotificationService().sendOrderUpdateNotification(
          order.customerId,
          order.orderNumber.isNotEmpty ? order.orderNumber : orderId,
          newStatus.displayName,
        );
      }
    } catch (e) {
      AppLogger.warn('Could not emit order status notification: $e', tag: 'OrderService');
    }
  }

  /// Fetch single order by ID
  static Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _collection.doc(orderId).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return OrderModel.fromJson(data);
    } catch (e) {
      AppLogger.error('Error fetching order $orderId: $e', tag: 'OrderService');
      return null;
    }
  }

  /// Get today's KPI metrics for Admin Dashboard
  static Future<Map<String, dynamic>> getTodaySummary() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

      final snapshot = await _collection
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .get();

      double todaySales = 0;
      int todayOrders = snapshot.docs.length;
      int pendingOrders = 0;
      int deliveredOrders = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['status'] ?? '').toString().toLowerCase();
        final total = (data['total'] ?? 0).toDouble();

        if (status != 'cancelled') {
          todaySales += total;
        }
        if (status == 'pending') {
          pendingOrders++;
        } else if (status == 'delivered') {
          deliveredOrders++;
        }
      }

      return {
        'todaySales': todaySales,
        'todayOrders': todayOrders,
        'pendingOrders': pendingOrders,
        'deliveredOrders': deliveredOrders,
      };
    } catch (e) {
      AppLogger.error('Error fetching today summary: $e', tag: 'OrderService');
      return {
        'todaySales': 0.0,
        'todayOrders': 0,
        'pendingOrders': 0,
        'deliveredOrders': 0,
      };
    }
  }
}
