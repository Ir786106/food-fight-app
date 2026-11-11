import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/services/order_service.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/utils/safe_change_notifier.dart';

/// Provider managing order state for Customer tracking and Admin order management
class OrderProvider extends ChangeNotifier with SafeChangeNotifier {
  List<OrderModel> _customerOrders = [];
  List<OrderModel> _adminOrders = [];
  OrderModel? _currentOrder;
  bool _isTrackingLoading = false;
  String? _trackingError;
  bool _isLoading = false;
  String? _errorMessage;
  String _adminFilter = 'all';
  String? _adminBranchId;
  String? _adminStatus;
  int _adminGeneration = 0;
  bool _pagingAdmin = false;
  String? _adminPageError;
  OrderPage? _liveAdminPage;
  OrderPage? _olderPage;
  final _historicalOrders = <String, OrderModel>{};
  bool _watchingAdminOrders = false;

  StreamSubscription<OrderPage>? _customerOrdersSub;
  StreamSubscription<List<OrderModel>>? _activeCustomerSub;
  String? _customerScope;
  int _customerGeneration = 0;
  OrderPage? _customerHead;
  OrderPage? _customerTail;
  List<OrderModel> _activeCustomerOrders = [];
  final _customerArchive = <String, OrderModel>{};
  bool _pagingCustomer = false;
  String? _customerPageError;

  bool get canLoadMoreCustomerOrders => !_pagingCustomer &&
      (_customerTail ?? _customerHead)?.mayHaveMore == true;
  bool get isPagingCustomerOrders => _pagingCustomer;
  String? get customerPageError => _customerPageError;
  StreamSubscription<OrderPage>? _adminOrdersSub;
  StreamSubscription<OrderModel?>? _trackingSub;

  List<OrderModel> get customerOrders => List.unmodifiable(_customerOrders);
  List<OrderModel> get adminOrders => List.unmodifiable(_adminOrders);
  OrderModel? get currentOrder => _currentOrder;
  bool get isTrackingLoading => _isTrackingLoading;
  String? get trackingError => _trackingError;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get adminFilter => _adminFilter;
  bool isWatchingAdminScope(String? branchId) => _watchingAdminOrders && branchId == _adminBranchId;
  bool get isPagingAdminOrders => _pagingAdmin;
  String? get adminPageError => _adminPageError;
  bool get canLoadMoreAdminOrders => !_isLoading && !_pagingAdmin &&
      (_olderPage ?? _liveAdminPage)?.mayHaveMore == true;

  /// Filtered orders for Admin Orders screen
  List<OrderModel> get filteredAdminOrders {
    if (_adminFilter == 'all') return _adminOrders;
    return _adminOrders.where((order) => order.status == OrderStatus.fromString(_adminFilter)).toList();
  }

  // Status counts for admin tab badges
  int get allCount => _adminOrders.length;
  int get pendingCount => _adminOrders.where((o) => o.status == OrderStatus.pending).length;
  int get preparingCount => _adminOrders.where((o) => o.status == OrderStatus.preparing).length;
  int get readyCount => _adminOrders.where((o) => o.status == OrderStatus.ready).length;
  int get outForDeliveryCount => _adminOrders.where((o) => o.status == OrderStatus.outForDelivery).length;
  int get deliveredCount => _adminOrders.where((o) => o.status == OrderStatus.delivered).length;
  int get cancelledCount => _adminOrders.where((o) => o.status == OrderStatus.cancelled).length;
  int get activeOrdersCount => _adminOrders.where((order) => !order.status.isTerminal).length;

  void _mergeCustomerOrders() {
    _customerOrders = {
      ..._customerArchive,
      for (final order in _customerHead?.orders ?? const <OrderModel>[]) order.id: order,
      for (final order in _activeCustomerOrders) order.id: order,
    }.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void watchCustomerOrders(String customerId) {
    if (customerId.isEmpty) return;
    final generation = ++_customerGeneration;
    if (_customerScope != customerId) _customerOrders = [];
    _customerScope = customerId;
    _customerHead = null;
    _customerTail = null;
    _customerArchive.clear();
    _activeCustomerOrders = [];
    _pagingCustomer = false;
    _customerPageError = null;
    _isLoading = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    void onError(Object error) {
      if (generation != _customerGeneration) return;
      _isLoading = false;
      _errorMessage = 'Unable to load your orders. Please try again.';
      _customerPageError = _errorMessage;
      AppLogger.error('Customer orders watch error: $error', tag: 'OrderProvider');
      notifyListeners();
    }

    _activeCustomerSub?.cancel();
    _activeCustomerSub = OrderService.watchActiveCustomerOrders(customerId).listen(
      (orders) {
        if (generation != _customerGeneration) return;
        final activeIds = orders.map((order) => order.id).toSet();
        for (final order in _activeCustomerOrders) {
          if (!activeIds.contains(order.id)) {
            unawaited(_retainCompletedCustomerOrder(order.id, generation));
          }
        }
        _activeCustomerOrders = orders;
        _mergeCustomerOrders();
        notifyListeners();
      },
      onError: onError,
    );
    _customerOrdersSub?.cancel();
    _customerOrdersSub = OrderService.watchCustomerOrderPage(customerId).listen(
      (page) {
        if (generation != _customerGeneration) return;
        if (_pagingCustomer || _customerTail != null) {
          for (final order in _customerHead?.orders ?? const <OrderModel>[]) {
            if (order.status.isTerminal) _customerArchive[order.id] = order;
          }
        }
        _customerHead = page;
        _mergeCustomerOrders();
        _isLoading = false;
        notifyListeners();
      },
      onError: onError,
    );
  }

  Future<void> _retainCompletedCustomerOrder(String orderId, int generation) async {
    final order = await OrderService.getOrder(orderId);
    if (generation != _customerGeneration ||
        order == null || order.customerId != _customerScope ||
        !order.status.isTerminal) {
      return;
    }
    _customerArchive[order.id] = order;
    _mergeCustomerOrders();
    notifyListeners();
  }
  Future<void> loadMoreCustomerOrders() async {
    final customerId = _customerScope;
    if (customerId == null || !canLoadMoreCustomerOrders) return;
    final generation = _customerGeneration;
    final cursor = _customerTail ?? _customerHead!;
    _pagingCustomer = true;
    _customerPageError = null;
    notifyListeners();
    try {
      final page = await OrderService.fetchNextCustomerOrderPage(customerId, cursor);
      if (generation != _customerGeneration) return;
      _customerTail = page;
      for (final order in page.orders) {
        if (order.status.isTerminal) _customerArchive[order.id] = order;
      }
      _mergeCustomerOrders();
    } catch (error) {
      if (generation != _customerGeneration) return;
      _customerPageError = 'Unable to load older orders. Try again.';
      AppLogger.error('Customer page request failed: $error', tag: 'OrderProvider');
    } finally {
      if (generation == _customerGeneration) {
        _pagingCustomer = false;
        notifyListeners();
      }
    }
  }
  /// Watch all orders for Admin panel (scoped by branchId if provided)
  void watchAdminOrders({String? status, String? branchId}) {
    if (!_watchingAdminOrders || branchId != _adminBranchId || status != _adminStatus) {
      _adminOrders = [];
    }
    _watchingAdminOrders = true;
    _adminBranchId = branchId;
    _adminStatus = status;
    refreshAdminOrders();
  }

  Future<void> loadMoreAdminOrders() async {
    if (!canLoadMoreAdminOrders) return;
    final cursor = _olderPage ?? _liveAdminPage!;
    final generation = _adminGeneration;
    _pagingAdmin = true;
    _adminPageError = null;
    notifyListeners();
    try {
      final next = await OrderService.fetchNextAdminOrderPage(
        after: cursor,
        status: _adminStatus,
        branchId: _adminBranchId,
      );
      if (generation != _adminGeneration) return;
      _olderPage = next;
      _historicalOrders.addEntries(next.orders.map((order) => MapEntry(order.id, order)));
      _mergeAdminOrders();
    } catch (error) {
      if (generation != _adminGeneration) return;
      _adminPageError = 'Unable to load older orders. Try again.';
      AppLogger.error('Order page request failed: $error', tag: 'OrderProvider');
    } finally {
      if (generation == _adminGeneration) {
        _pagingAdmin = false;
        notifyListeners();
      }
    }
  }

  void _mergeAdminOrders() {
    _adminOrders = {
      ..._historicalOrders,
      for (final order in _liveAdminPage?.orders ?? const <OrderModel>[]) order.id: order,
    }.values.toList()
      ..sort((a, b) {
        final comparison = b.createdAt.compareTo(a.createdAt);
        return comparison == 0 ? b.id.compareTo(a.id) : comparison;
      });
  }

  void refreshAdminOrders() {
    if (!_watchingAdminOrders) return;
    final generation = ++_adminGeneration;
    _liveAdminPage = null;
    _olderPage = null;
    _historicalOrders.clear();
    _pagingAdmin = false;
    _adminPageError = null;
    _isLoading = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    _adminOrdersSub?.cancel();
    _adminOrdersSub = OrderService.watchAdminOrderPage(
      status: _adminStatus,
      branchId: _adminBranchId,
    ).listen((page) {
      if (generation != _adminGeneration) return;
      // New orders can move rows out of the live window while a page is loading.
      if (_pagingAdmin || _olderPage != null) {
        for (final order in _liveAdminPage?.orders ?? const <OrderModel>[]) {
          _historicalOrders[order.id] = order;
        }
      }
      _liveAdminPage = page;
      _mergeAdminOrders();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }, onError: (Object error) {
      if (generation != _adminGeneration) return;
      _adminOrders = [];
      _historicalOrders.clear();
      _liveAdminPage = null;
      _olderPage = null;
      _pagingAdmin = false;
      _adminGeneration++;
      _isLoading = false;
      _errorMessage = 'Unable to load orders for this branch.';
      AppLogger.error('Admin orders watch error: $error', tag: 'OrderProvider');
      notifyListeners();
    });
  }

  /// Watch a specific order in real-time (for Customer Order Tracking)
  void watchOrder(String orderId) {
    if (orderId.isEmpty) return;
    _trackingSub?.cancel();
    if (_currentOrder?.id != orderId) _currentOrder = null;
    _isTrackingLoading = true;
    _trackingError = null;
    notifyListenersPostFrame();
    _trackingSub = OrderService.watchOrder(orderId).listen(
      (order) {
        _currentOrder = order;
        _isTrackingLoading = false;
        _trackingError = null;
        notifyListeners();
      },
      onError: (e) {
        AppLogger.error('Order tracking watch error: $e', tag: 'OrderProvider');
        _isTrackingLoading = false;
        _trackingError = 'Unable to load this order. Please try again.';
        notifyListeners();
      },
    );
  }

  /// Set Admin order filter tab
  void setAdminFilter(String filter) {
    if (_adminFilter != filter) {
      _adminFilter = filter;
      notifyListeners();
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? cancellationReason,
  }) async {
    try {
      _errorMessage = null;
      await OrderService.updateOrderStatus(
        orderId,
        newStatus,
        cancellationReason: cancellationReason,
      );
      // If currently tracking this order, update local instance optimistically
      if (_currentOrder != null && _currentOrder!.id == orderId) {
        _currentOrder = _currentOrder!.copyWith(
          status: newStatus,
          cancellationReason: cancellationReason,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update order status: $e';
      AppLogger.error('Update order status error: $e', tag: 'OrderProvider');
      notifyListeners();
      return false;
    }
  }

  /// Remove account-specific streams and cached data when the signed-in account changes.
  void reset() {
    _customerGeneration++;
    _activeCustomerSub?.cancel();
    _activeCustomerSub = null;
    _customerScope = null;
    _customerHead = null;
    _customerTail = null;
    _activeCustomerOrders = [];
    _customerArchive.clear();
    _pagingCustomer = false;
    _customerPageError = null;
    _customerOrdersSub?.cancel();
    _adminOrdersSub?.cancel();
    _trackingSub?.cancel();
    _customerOrdersSub = null;
    _adminOrdersSub = null;
    _trackingSub = null;
    _customerOrders = [];
    _adminOrders = [];
    _currentOrder = null;
    _isTrackingLoading = false;
    _trackingError = null;
    _isLoading = false;
    _errorMessage = null;
    _adminFilter = 'all';
    _adminBranchId = null;
    _adminStatus = null;
    _adminGeneration++;
    _liveAdminPage = null;
    _olderPage = null;
    _historicalOrders.clear();
    _adminPageError = null;
    _pagingAdmin = false;
    _watchingAdminOrders = false;
    notifyListeners();
  }

  /// Cancel order by customer with backend 5-minute window & pending-status validation
  Future<bool> cancelOrderByCustomer(String orderId, {String? reason}) async {
    try {
      _isLoading = true;
      notifyListeners();
      await OrderService.cancelOrderByCustomer(orderId, reason: reason);
      if (_currentOrder != null && _currentOrder!.id == orderId) {
        _currentOrder = _currentOrder!.copyWith(
          status: OrderStatus.cancelled,
          cancellationReason: reason ?? 'Cancelled by customer',
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      AppLogger.error('Customer cancel order error: $e', tag: 'OrderProvider');
      notifyListeners();
      return false;
    }
  }

  /// Get order synchronously from local cached list
  OrderModel? getOrderById(String orderId) {
    try {
      return _customerOrders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      try {
        return _adminOrders.firstWhere((o) => o.id == orderId);
      } catch (_) {
        return _currentOrder?.id == orderId ? _currentOrder : null;
      }
    }
  }

  /// Fetch order by ID from backend
  Future<OrderModel?> fetchOrderById(String orderId) => getOrder(orderId);

  /// Get order by ID
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      return await OrderService.getOrder(orderId);
    } catch (e) {
      AppLogger.error('Get order error: $e', tag: 'OrderProvider');
      return null;
    }
  }

  @override
  void dispose() {
    _customerGeneration++;
    _activeCustomerSub?.cancel();
    _activeCustomerSub = null;
    _customerScope = null;
    _customerHead = null;
    _customerTail = null;
    _activeCustomerOrders = [];
    _customerArchive.clear();
    _pagingCustomer = false;
    _customerPageError = null;
    _adminGeneration++;
    _customerOrdersSub?.cancel();
    _adminOrdersSub?.cancel();
    _trackingSub?.cancel();
    super.dispose();
  }
}
