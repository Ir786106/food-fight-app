import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Provider for real-time Admin Dashboard KPIs, stats, and quick overview
class AdminDashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  // Sales metrics
  double _todaySales = 0.0;
  double _weeklySales = 0.0;
  double _monthlySales = 0.0;

  // Order counts
  int _todayOrdersCount = 0;
  int _pendingOrdersCount = 0;
  int _preparingOrdersCount = 0;
  int _readyOrdersCount = 0;
  int _outForDeliveryOrdersCount = 0;
  int _completedOrdersCount = 0;
  int _cancelledOrdersCount = 0;

  // Operational metrics
  int _activeRidersCount = 0;
  int _newCustomersCount = 0;

  // Lists
  List<OrderModel> _recentOrders = [];
  List<MenuItemModel> _popularItems = [];

  StreamSubscription<QuerySnapshot>? _ordersSubscription;
  StreamSubscription<QuerySnapshot>? _ridersSubscription;
  StreamSubscription<QuerySnapshot>? _customersSubscription;
  StreamSubscription<QuerySnapshot>? _popularItemsSubscription;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get todaySales => _todaySales;
  double get weeklySales => _weeklySales;
  double get monthlySales => _monthlySales;

  int get todayOrdersCount => _todayOrdersCount;
  int get pendingOrdersCount => _pendingOrdersCount;
  int get preparingOrdersCount => _preparingOrdersCount;
  int get readyOrdersCount => _readyOrdersCount;
  int get outForDeliveryOrdersCount => _outForDeliveryOrdersCount;
  int get completedOrdersCount => _completedOrdersCount;
  int get cancelledOrdersCount => _cancelledOrdersCount;

  int get activeRidersCount => _activeRidersCount;
  int get newCustomersCount => _newCustomersCount;

  List<OrderModel> get recentOrders => List.unmodifiable(_recentOrders);
  List<MenuItemModel> get popularItems => List.unmodifiable(_popularItems);

  AdminDashboardProvider() {
    init();
  }

  void init() {
    watchDashboardData();
  }

  /// Watch live dashboard data across Firestore collections
  void watchDashboardData() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Listen to orders for sales & status counts
    _ordersSubscription?.cancel();
    _ordersSubscription = _firestore
        .collection(FirestoreCollections.orders)
        .orderBy('createdAt', descending: true)
        .limit(150)
        .snapshots()
        .listen(
      (snapshot) {
        _processOrders(snapshot.docs);
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load order metrics: $e';
        AppLogger.error('Dashboard orders watch error: $e', tag: 'AdminDashboardProvider');
        notifyListeners();
      },
    );

    // 2. Watch active riders
    _ridersSubscription?.cancel();
    _ridersSubscription = _firestore
        .collection(FirestoreCollections.riders)
        .snapshots()
        .listen(
      (snapshot) {
        _activeRidersCount = snapshot.docs.where((d) {
          final data = d.data();
          final isOnline = data['isOnline'] == true || data['isOnline'] == 1;
          final isAvailable = data['isAvailable'] == true || data['isAvailable'] == 1;
          return isOnline || isAvailable;
        }).length;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Failed to load riders count: $e';
        AppLogger.error('Dashboard riders watch error: $e', tag: 'AdminDashboardProvider');
        notifyListeners();
      },
    );

    // 3. Watch customers count
    _customersSubscription?.cancel();
    _customersSubscription = _firestore
        .collection(FirestoreCollections.users)
        .where('role', isEqualTo: 'customer')
        .snapshots()
        .listen(
      (snapshot) {
        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
        _newCustomersCount = snapshot.docs.where((d) {
          final data = d.data();
          final createdAt = data['createdAt'] as int? ?? 0;
          return createdAt >= thirtyDaysAgo;
        }).length;
        if (_newCustomersCount == 0) {
          _newCustomersCount = snapshot.docs.length;
        }
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Failed to load customer count: $e';
        AppLogger.error('Dashboard customers watch error: $e', tag: 'AdminDashboardProvider');
        notifyListeners();
      },
    );

    // 4. Watch popular menu items
    _popularItemsSubscription?.cancel();
    _popularItemsSubscription = _firestore
        .collection(FirestoreCollections.menuItems)
        .where('isActive', isEqualTo: 1)
        .snapshots()
        .listen(
      (snapshot) {
        final items = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return MenuItemModel.fromJson(data);
        }).toList();

        final popular = items.where((i) => i.isPopular).toList();
        if (popular.isNotEmpty) {
          _popularItems = popular;
        } else {
          items.sort((a, b) => b.rating.compareTo(a.rating));
          _popularItems = items.take(5).toList();
        }
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Failed to load popular items: $e';
        AppLogger.error('Dashboard popular items watch error: $e', tag: 'AdminDashboardProvider');
        notifyListeners();
      },
    );
  }

  void _processOrders(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final sevenDaysAgo = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final thirtyDaysAgo = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;

    double todaySalesAcc = 0;
    double weekSalesAcc = 0;
    double monthSalesAcc = 0;

    int todayOrdersAcc = 0;
    int pendingAcc = 0;
    int preparingAcc = 0;
    int readyAcc = 0;
    int outForDeliveryAcc = 0;
    int completedAcc = 0;
    int cancelledAcc = 0;

    final parsedOrders = <OrderModel>[];

    for (var doc in docs) {
      final data = doc.data();
      data['id'] = doc.id;
      final order = OrderModel.fromJson(data);
      parsedOrders.add(order);

      final createdAt = order.createdAt.millisecondsSinceEpoch;
      final total = order.total;
      final status = order.status;

      // Status counters
      switch (status) {
        case OrderStatus.pending:
        case OrderStatus.accepted:
          pendingAcc++;
          break;
        case OrderStatus.preparing:
          preparingAcc++;
          break;
        case OrderStatus.ready:
          readyAcc++;
          break;
        case OrderStatus.assigned:
        case OrderStatus.pickedUp:
        case OrderStatus.outForDelivery:
          outForDeliveryAcc++;
          break;
        case OrderStatus.delivered:
          completedAcc++;
          break;
        case OrderStatus.cancelled:
          cancelledAcc++;
          break;
      }

      // Sales calculations (exclude cancelled)
      if (status != OrderStatus.cancelled) {
        if (createdAt >= startOfToday) {
          todaySalesAcc += total;
          todayOrdersAcc++;
        }
        if (createdAt >= sevenDaysAgo) {
          weekSalesAcc += total;
        }
        if (createdAt >= thirtyDaysAgo) {
          monthSalesAcc += total;
        }
      }
    }

    _todaySales = todaySalesAcc;
    _weeklySales = weekSalesAcc;
    _monthlySales = monthSalesAcc;

    _todayOrdersCount = todayOrdersAcc;
    _pendingOrdersCount = pendingAcc;
    _preparingOrdersCount = preparingAcc;
    _readyOrdersCount = readyAcc;
    _outForDeliveryOrdersCount = outForDeliveryAcc;
    _completedOrdersCount = completedAcc;
    _cancelledOrdersCount = cancelledAcc;

    _recentOrders = parsedOrders.take(10).toList();
  }

  /// Force refresh
  Future<void> refresh() async {
    watchDashboardData();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _ridersSubscription?.cancel();
    _customersSubscription?.cancel();
    _popularItemsSubscription?.cancel();
    super.dispose();
  }
}
