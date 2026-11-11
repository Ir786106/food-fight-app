import 'dart:async';
import 'package:flutter/material.dart';
import '../models/rider_model.dart';
import '../models/order_model.dart';
import '../services/rider_service.dart';
import '../services/order_service.dart';
import '../core/utils/safe_change_notifier.dart';

class RiderProvider extends ChangeNotifier with SafeChangeNotifier {
  List<RiderModel> _riders = [];
  List<OrderModel> _assignedDeliveries = [];
  List<OrderModel> _completedDeliveries = [];
  List<OrderModel> _cancelledDeliveries = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<RiderModel>>? _ridersSub;
  StreamSubscription<List<OrderModel>>? _deliveriesSub;
  StreamSubscription<OrderPage>? _historySub;
  StreamSubscription<List<OrderModel>>? _earningsSub;
  List<OrderModel> _recentDeliveries = [];
  List<OrderModel> _earningsOrders = [];
  final Map<String, OrderModel> _olderDeliveries = {};
  OrderPage? _recentPage;
  OrderPage? _olderPage;
  String? _deliveryRiderId;
  int _deliveryGeneration = 0;
  bool _loadingHistory = false;
  String? _historyError;
  bool _earningsLoading = false;
  bool _earningsUnavailable = false;

  StreamSubscription<RiderModel?>? _profileSub;
  RiderModel? _currentRider;
  RiderModel? get currentRider => _currentRider;
  bool get isOnline => _currentRider?.isOnline == true;

  List<RiderModel> get riders => List.unmodifiable(_riders);
  List<RiderModel> get activeRiders =>
      _riders.where((r) => r.isActive).toList();
  List<RiderModel> get onlineRiders =>
      _riders.where((r) => r.isActive && r.isOnline).toList();
  List<OrderModel> get assignedDeliveries => {
        for (final order in _recentDeliveries.where((order) => !order.status.isTerminal))
          order.id: order,
        for (final order in _assignedDeliveries) order.id: order,
      }.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  List<OrderModel> get completedDeliveries =>
      List.unmodifiable(_completedDeliveries);
  List<OrderModel> get cancelledDeliveries =>
      List.unmodifiable(_cancelledDeliveries);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<OrderModel> get earningsOrders => {
        for (final order in _completedDeliveries) order.id: order,
        for (final order in _earningsOrders) order.id: order,
      }.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  bool get earningsLoading => _earningsLoading;
  bool get earningsUnavailable => _earningsUnavailable;
  bool get hasOlderDeliveries =>
      (_olderPage ?? _recentPage)?.mayHaveMore ?? false;
  bool get loadingHistory => _loadingHistory;
  String? get historyError => _historyError;

  String? _fleetBranchId;

  void watchAllRiders({String? branchId}) {
    if (_fleetBranchId != branchId) _riders = [];
    _fleetBranchId = branchId;
    _isLoading = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    _ridersSub?.cancel();
    _ridersSub = RiderService.watchAllRiders(branchId: branchId).listen(
      (items) {
        _riders = items;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load riders: $e';
        notifyListeners();
      },
    );
  }

  void watchRiderDeliveries(String riderId, {String? riderPhone}) {
    if (riderId.isEmpty) return;
    _clearDeliveryWatch();
    _currentRider = null;
    _deliveryRiderId = riderId;
    final generation = _deliveryGeneration;
    _isLoading = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    _profileSub?.cancel();
    _profileSub = RiderService.watchRider(riderId).listen((rider) {
      _currentRider = rider;
      notifyListeners();
    }, onError: (_) {
      _errorMessage = 'Unable to load your rider profile. Please try again.';
      notifyListeners();
    });

    _deliveriesSub?.cancel();
    _deliveriesSub = OrderService.watchActiveRiderOrders(riderId).listen(
      (orders) {
        final activeIds = orders.map((order) => order.id).toSet();
        for (final previous in _assignedDeliveries) {
          if (!activeIds.contains(previous.id)) {
            unawaited(_retainFinishedDelivery(previous.id, riderId, generation));
          }
        }
        _assignedDeliveries = orders;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _errorMessage = 'Unable to load deliveries. Please try again.';
        notifyListeners();
      },
    );
    _historySub = OrderService.watchRiderOrderPage(riderId).listen((page) {
      if (_loadingHistory || _olderPage != null) {
        for (final order in _recentDeliveries.where((order) => order.status.isTerminal)) {
          _olderDeliveries[order.id] = order;
        }
      }
      _recentPage = page;
      _recentDeliveries = page.orders;
      _updateHistory();
      notifyListeners();
    }, onError: (_) {
      _errorMessage = 'Unable to load deliveries. Please try again.';
      notifyListeners();
    });
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final since = monthStart.isBefore(weekStart) ? monthStart : weekStart;
    _earningsLoading = true;
    _earningsSub = OrderService.watchRecentRiderEarnings(riderId, since).listen(
      (orders) {
        _earningsOrders = orders;
        _earningsLoading = false;
        _earningsUnavailable = false;
        notifyListeners();
      },
      onError: (_) {
        _earningsLoading = false;
        _earningsUnavailable = true;
        notifyListeners();
      },
    );
  }

  Future<void> _retainFinishedDelivery(
      String orderId, String riderId, int generation) async {
    final order = await OrderService.getOrder(orderId);
    if (generation != _deliveryGeneration ||
        order == null || order.riderId != riderId || !order.status.isTerminal) {
      return;
    }
    _olderDeliveries[order.id] = order;
    _updateHistory();
    notifyListeners();
  }

  Future<void> loadOlderDeliveries() async {
    final riderId = _deliveryRiderId;
    final cursor = _olderPage ?? _recentPage;
    if (riderId == null || cursor == null || !hasOlderDeliveries || _loadingHistory) {
      return;
    }
    final generation = _deliveryGeneration;
    _loadingHistory = true;
    _historyError = null;
    notifyListeners();
    try {
      final page = await OrderService.fetchNextRiderOrderPage(riderId, cursor);
      if (generation != _deliveryGeneration) return;
      _olderPage = page;
      for (final order in page.orders.where((order) => order.status.isTerminal)) {
        _olderDeliveries.putIfAbsent(order.id, () => order);
      }
      _updateHistory();
    } catch (_) {
      if (generation == _deliveryGeneration) {
        _historyError = 'Unable to load older orders. Please try again.';
      }
    } finally {
      if (generation == _deliveryGeneration) {
        _loadingHistory = false;
        notifyListeners();
      }
    }
  }

  void _updateHistory() {
    final orders = {
      ..._olderDeliveries,
      for (final order in _recentDeliveries) order.id: order,
    }.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _completedDeliveries =
        orders.where((order) => order.status == OrderStatus.delivered).toList();
    _cancelledDeliveries =
        orders.where((order) => order.status == OrderStatus.cancelled).toList();
  }

  void _clearDeliveryWatch() {
    _deliveryGeneration++;
    _profileSub?.cancel();
    _deliveriesSub?.cancel();
    _historySub?.cancel();
    _earningsSub?.cancel();
    _deliveryRiderId = null;
    _recentPage = null;
    _olderPage = null;
    _recentDeliveries = [];
    _olderDeliveries.clear();
    _assignedDeliveries = [];
    _completedDeliveries = [];
    _cancelledDeliveries = [];
    _earningsOrders = [];
    _loadingHistory = false;
    _historyError = null;
    _earningsLoading = false;
    _earningsUnavailable = false;
  }

  Future<bool> createRider(RiderModel rider) async {
    try {
      await RiderService.createRider(rider);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createRiderWithAuth({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? vehicleType,
    String? vehicleNumber,
  }) async {
    try {
      await RiderService.createRiderWithAuth(
        name: name,
        email: email,
        password: password,
        phone: phone,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRider(RiderModel rider) async {
    try {
      await RiderService.updateRider(rider);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleActive(String riderId, bool isActive) async {
    try {
      await RiderService.setRiderActive(riderId, isActive);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleOnline(String riderId, bool isOnline) async {
    try {
      await RiderService.setRiderOnline(riderId, isOnline);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignRider({
    required String orderId,
    required String riderId,
    required String riderName,
    String? riderPhone,
    String? expectedRiderId,
  }) async {
    try {
      await RiderService.assignRiderToOrder(
        orderId: orderId,
        riderId: riderId,
        riderName: riderName,
        riderPhone: riderPhone,
        expectedRiderId: expectedRiderId,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> unassignRider(
      {required String orderId, required String expectedRiderId}) async {
    try {
      await RiderService.unassignRiderFromOrder(
          orderId: orderId, expectedRiderId: expectedRiderId);
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Bad state: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptDelivery(String orderId) async {
    try {
      await RiderService.acceptDelivery(orderId);
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Bad state: ', '');
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _ridersSub?.cancel();
    _clearDeliveryWatch();
    _ridersSub = null;
    _deliveriesSub = null;

    _profileSub = null;
    _riders = [];
    _currentRider = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ridersSub?.cancel();
    _clearDeliveryWatch();
    super.dispose();
  }
}
