import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/logger.dart';
import '../core/utils/safe_change_notifier.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/report_model.dart';
import '../services/order_service.dart';

class AdminDashboardProvider extends ChangeNotifier with SafeChangeNotifier {
  static const orderSampleLimit = 200;

  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ridersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _popularItemsSubscription;

  bool isLoading = false;
  String? errorMessage;
  String? currentBranchId;
  double todaySales = 0;
  double weeklySales = 0;
  double monthlySales = 0;
  double? averageDeliveryMinutes;
  int todayOrdersCount = 0;
  int activeRidersCount = 0;
  int newCustomersCount = 0;
  List<OrderModel> _recentOrders = [];
  List<MenuItemModel> _popularItems = [];
  List<DailySalesStat> _dailySales = [];
  List<MapEntry<String, int>> _topSellers = [];
  final _counts = <OrderStatus, int>{};

  List<OrderModel> get recentOrders => List.unmodifiable(_recentOrders);
  List<MenuItemModel> get popularItems => List.unmodifiable(_popularItems);
  List<DailySalesStat> get dailySales => List.unmodifiable(_dailySales);
  List<MapEntry<String, int>> get topSellers => List.unmodifiable(_topSellers);

  int _count(OrderStatus status) => _counts[status] ?? 0;
  int get pendingOrdersCount =>
      _count(OrderStatus.pending) + _count(OrderStatus.accepted);
  int get preparingOrdersCount => _count(OrderStatus.preparing);
  int get readyOrdersCount => _count(OrderStatus.ready);
  int get outForDeliveryOrdersCount =>
      _count(OrderStatus.assigned) +
      _count(OrderStatus.pickedUp) +
      _count(OrderStatus.outForDelivery);
  int get completedOrdersCount => _count(OrderStatus.delivered);
  int get cancelledOrdersCount => _count(OrderStatus.cancelled);

  void init() => watchDashboardData();

  Future<void> refresh() async => watchDashboardData(branchId: currentBranchId);

  void watchDashboardData({String? branchId}) {
    cancelSubscriptions();
    if (currentBranchId != branchId) {
      _processOrders(const []);
      activeRidersCount = 0;
      _popularItems = [];
    }
    currentBranchId = branchId;
    isLoading = true;
    errorMessage = null;
    notifyListenersPostFrame();

    Query<Map<String, dynamic>> scoped(String path) {
      final collection = FirebaseFirestore.instance.collection(path);
      return branchId == null
          ? collection
          : collection.where('branchId', isEqualTo: branchId);
    }

    _ordersSubscription = OrderService.watchAllOrders(
      branchId: branchId,
      limit: orderSampleLimit,
    ).listen((orders) {
      _processOrders(orders);
      isLoading = false;
      errorMessage = null;
      notifyListeners();
    }, onError: (Object error) {
      isLoading = false;
      errorMessage = 'Unable to load order metrics for this branch.';
      AppLogger.error('Dashboard order query failed: $error',
          tag: 'AdminDashboardProvider');
      notifyListeners();
    });

    _ridersSubscription = scoped(FirestoreCollections.riders)
        .where('isOnline', whereIn: [true, 1])
        .limit(orderSampleLimit)
        .snapshots()
        .listen((snapshot) {
          activeRidersCount = snapshot.docs.where((doc) {
            final active = doc.data()['isActive'];
            return active == null || active == true || active == 1;
          }).length;
          notifyListeners();
        }, onError: (Object error) {
          AppLogger.error('Dashboard rider query failed: $error',
              tag: 'AdminDashboardProvider');
        });

    _popularItemsSubscription = scoped(FirestoreCollections.menuItems)
        .where('isActive', whereIn: [true, 1])
        .limit(orderSampleLimit)
        .snapshots()
        .listen((snapshot) {
          final items = snapshot.docs
              .map((doc) =>
                  MenuItemModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList()
            ..sort((a, b) => b.rating.compareTo(a.rating));
          final featured = items.where((item) => item.isPopular);
          _popularItems =
              (featured.isEmpty ? items : featured).take(5).toList();
          notifyListeners();
        }, onError: (Object error) {
          AppLogger.error('Dashboard menu query failed: $error',
              tag: 'AdminDashboardProvider');
        });
  }

  void _processOrders(List<OrderModel> orders) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final week = DateTime(now.year, now.month, now.day - 6);
    final month = DateTime(now.year, now.month, now.day - 29);
    final customers = <String>{};
    final dailyRevenue = <DateTime, double>{};
    final dailyCount = <DateTime, int>{};
    final quantities = <String, int>{};
    var deliveryMinutes = 0;
    var timedDeliveries = 0;

    _counts.clear();
    todaySales = 0;
    weeklySales = 0;
    monthlySales = 0;
    todayOrdersCount = 0;

    for (final order in orders) {
      _counts.update(order.status, (value) => value + 1, ifAbsent: () => 1);
      final day = DateUtils.dateOnly(order.createdAt.toLocal());
      if (order.status != OrderStatus.cancelled && day == today) {
        todayOrdersCount++;
      }
      if (!day.isBefore(month) && order.customerId.isNotEmpty) {
        customers.add(order.customerId);
      }
      if (order.status != OrderStatus.delivered) continue;

      final total = order.total;
      if (day == today) todaySales += total;
      if (!day.isBefore(week)) weeklySales += total;
      if (!day.isBefore(month)) monthlySales += total;
      dailyRevenue.update(day, (revenue) => revenue + total,
          ifAbsent: () => total);
      dailyCount.update(day, (value) => value + 1, ifAbsent: () => 1);
      for (final line in order.items) {
        quantities.update(line.food.name, (value) => value + line.quantity,
            ifAbsent: () => line.quantity);
      }
      final delivered =
          order.deliveredAt ?? order.timestampFor(OrderStatus.delivered);
      if (delivered != null && !delivered.isBefore(order.createdAt)) {
        timedDeliveries++;
        deliveryMinutes += delivered.difference(order.createdAt).inMinutes;
      }
    }

    final days =
        List.generate(7, (i) => DateTime(now.year, now.month, now.day - 6 + i));
    _dailySales = [
      for (final day in days)
        DailySalesStat(
            date: day,
            revenue: dailyRevenue[day] ?? 0,
            ordersCount: dailyCount[day] ?? 0),
    ];
    final ranked = quantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topSellers = ranked.take(5).toList();
    _recentOrders = orders.take(10).toList();
    newCustomersCount = customers.length;
    averageDeliveryMinutes =
        timedDeliveries == 0 ? null : deliveryMinutes / timedDeliveries;
  }

  void cancelSubscriptions() {
    _ordersSubscription?.cancel();
    _ridersSubscription?.cancel();
    _popularItemsSubscription?.cancel();
    _ordersSubscription = null;
    _ridersSubscription = null;
    _popularItemsSubscription = null;
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }
}
