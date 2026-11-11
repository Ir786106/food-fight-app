import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Keeps Firestore's original cursor, including the document ID tie-breaker.
class OrderPage {
  const OrderPage._(this.orders, this._lastDocument);

  factory OrderPage._fromSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      OrderPage._(
        [
          for (final doc in snapshot.docs)
            OrderModel.fromJson({...doc.data(), 'id': doc.id}),
        ],
        snapshot.docs.lastOrNull,
      );

  final List<OrderModel> orders;
  final DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool get mayHaveMore => orders.length == OrderService.pageSize;
}

/// Order Service for Customer ordering and Admin order management
class OrderService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection(FirestoreCollections.orders);

  /// Generate unique, human-readable order number like "FF-83921"
  static String generateOrderNumber() {
    final now = DateTime.now();
    final timeTail = (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    final random = Random().nextInt(90) + 10;
    return 'FF-$timeTail$random';
  }

  /// Watch orders for a specific customer in real-time
  static Stream<List<OrderModel>> watchCustomerOrders(String customerId, {int? limit}) {
    Query query = _collection
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true);
    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return OrderModel.fromJson(data);
      }).toList();
    });
  }

  static Query<Map<String, dynamic>> _customerQuery(String customerId) =>
      FirebaseFirestore.instance.collection(FirestoreCollections.orders)
          .where('customerId', isEqualTo: customerId);

  static Query<Map<String, dynamic>> _riderQuery(String riderId) =>
      FirebaseFirestore.instance.collection(FirestoreCollections.orders)
          .where('riderId', isEqualTo: riderId);

  static Stream<OrderPage> watchRiderOrderPage(String riderId) =>
      _riderQuery(riderId).orderBy('createdAt', descending: true)
          .limit(pageSize).snapshots().map(OrderPage._fromSnapshot);

  static Stream<List<OrderModel>> watchActiveRiderOrders(String riderId) =>
      _riderQuery(riderId)
          .where('status', whereNotIn: ['delivered', 'cancelled', 'canceled', 'failed'])
          .snapshots()
          .map((snapshot) => OrderPage._fromSnapshot(snapshot).orders
              .where((order) => !order.status.isTerminal).toList());

  static Stream<List<OrderModel>> watchRecentRiderEarnings(
    String riderId, DateTime since,
  ) =>
      _riderQuery(riderId)
          .where('status', isEqualTo: 'delivered')
          .where('updatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .snapshots()
          .map((snapshot) => OrderPage._fromSnapshot(snapshot).orders);

  static Future<OrderPage> fetchNextRiderOrderPage(
    String riderId, OrderPage after,
  ) async {
    final cursor = after._lastDocument;
    if (cursor == null) return const OrderPage._([], null);
    final snapshot = await _riderQuery(riderId)
        .orderBy('createdAt', descending: true)
        .startAfterDocument(cursor)
        .limit(pageSize)
        .get(const GetOptions(source: Source.server));
    return OrderPage._fromSnapshot(snapshot);
  }

  static Stream<OrderPage> watchCustomerOrderPage(String customerId) =>
      _customerQuery(customerId).orderBy('createdAt', descending: true)
          .limit(pageSize).snapshots().map(OrderPage._fromSnapshot);

  static Stream<List<OrderModel>> watchActiveCustomerOrders(String customerId) =>
      _customerQuery(customerId)
          .where('status', whereNotIn: ['delivered', 'cancelled', 'canceled', 'failed'])
          .snapshots()
          .map((snapshot) => OrderPage._fromSnapshot(snapshot).orders
              .where((order) => !order.status.isTerminal).toList());

  static Future<OrderPage> fetchNextCustomerOrderPage(
    String customerId, OrderPage after,
  ) async {
    final cursor = after._lastDocument;
    if (cursor == null) return const OrderPage._([], null);
    final snapshot = await _customerQuery(customerId)
        .orderBy('createdAt', descending: true)
        .startAfterDocument(cursor)
        .limit(pageSize)
        .get(const GetOptions(source: Source.server));
    return OrderPage._fromSnapshot(snapshot);
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

  /// Watch all orders (Admin panel), strictly scoped by branchId and status at query level
  static Stream<List<OrderModel>> watchAllOrders({
    String? status,
    String? branchId,
    int? limit,
  }) {
    Query query = _collection;

    if (branchId != null && branchId.isNotEmpty && branchId.toLowerCase() != 'all') {
      query = query.where('branchId', isEqualTo: branchId);
    }

    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      final s = OrderStatus.fromString(status).name;
      query = query.where('status', isEqualTo: s);
    }

    query = query.orderBy('createdAt', descending: true);

    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return OrderModel.fromJson(data);
      }).toList();
    });
  }

  static Query<Map<String, dynamic>> _adminQuery({
    String? status,
    String? branchId,
  }) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(FirestoreCollections.orders);
    if (branchId != null && branchId.isNotEmpty && branchId.toLowerCase() != 'all') {
      query = query.where('branchId', isEqualTo: branchId);
    }
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      query = query.where('status', isEqualTo: OrderStatus.fromString(status).name);
    }
    return query.orderBy('createdAt', descending: true);
  }

  static Stream<OrderPage> watchAdminOrderPage({
    String? status,
    String? branchId,
  }) => _adminQuery(status: status, branchId: branchId)
      .limit(pageSize)
      .snapshots()
      .map(OrderPage._fromSnapshot);

  static Future<OrderPage> fetchNextAdminOrderPage({
    required OrderPage after,
    String? status,
    String? branchId,
  }) async {
    final cursor = after._lastDocument;
    if (cursor == null) return const OrderPage._([], null);
    final snapshot = await _adminQuery(status: status, branchId: branchId)
        .startAfterDocument(cursor)
        .limit(pageSize)
        .get(const GetOptions(source: Source.server));
    return OrderPage._fromSnapshot(snapshot);
  }

  static const pageSize = 50;

  /// The backend validates the actor and records the transition atomically.
  static Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? cancellationReason,
    bool codCollected = false,
  }) async {
    await FirebaseFunctions.instance.httpsCallable('mutateOrder').call({
      'action': 'transition',
      'orderId': orderId,
      'status': newStatus.name,
      'reason': cancellationReason,
      'codCollected': codCollected,
    });
  }

  /// The server checks ownership, pending state and the cancellation window.
  static Future<bool> cancelOrderByCustomer(String orderId, {String? reason}) async {
    await updateOrderStatus(
      orderId,
      OrderStatus.cancelled,
      cancellationReason: reason ?? 'Cancelled by customer',
    );
    return true;
  }

  static Future<void> dispatchRider(String orderId) async {
    await FirebaseFunctions.instance.httpsCallable('mutateOrder').call({
      'action': 'dispatch',
      'orderId': orderId,
    });
  }

  static Future<void> settleCod(String orderId, double amountPkr) async {
    await FirebaseFunctions.instance.httpsCallable('mutateOrder').call({
      'action': 'settle',
      'orderId': orderId,
      'amountPkr': amountPkr,
    });
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
