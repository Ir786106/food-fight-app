import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/services/order_service.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Provider managing order state for Customer tracking and Admin order management
class OrderProvider extends ChangeNotifier {
  List<OrderModel> _customerOrders = [];
  List<OrderModel> _adminOrders = [];
  OrderModel? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;
  String _adminFilter = 'all';

  StreamSubscription<List<OrderModel>>? _customerOrdersSub;
  StreamSubscription<List<OrderModel>>? _adminOrdersSub;
  StreamSubscription<OrderModel?>? _trackingSub;

  List<OrderModel> get customerOrders => List.unmodifiable(_customerOrders);
  List<OrderModel> get adminOrders => List.unmodifiable(_adminOrders);
  OrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get adminFilter => _adminFilter;

  /// Filtered orders for Admin Orders screen
  List<OrderModel> get filteredAdminOrders {
    if (_adminFilter == 'all') return _adminOrders;
    return _adminOrders.where((o) {
      final s = o.status.name.toLowerCase();
      final filter = _adminFilter.toLowerCase().replaceAll(' ', '_');
      return s == filter || s == _adminFilter.toLowerCase();
    }).toList();
  }

  // Status counts for admin tab badges
  int get allCount => _adminOrders.length;
  int get pendingCount => _adminOrders.where((o) => o.status == OrderStatus.pending).length;
  int get preparingCount => _adminOrders.where((o) => o.status == OrderStatus.preparing).length;
  int get readyCount => _adminOrders.where((o) => o.status == OrderStatus.ready).length;
  int get outForDeliveryCount => _adminOrders.where((o) => o.status == OrderStatus.outForDelivery).length;
  int get deliveredCount => _adminOrders.where((o) => o.status == OrderStatus.delivered).length;
  int get cancelledCount => _adminOrders.where((o) => o.status == OrderStatus.cancelled).length;

  /// Watch orders for a logged-in customer
  void watchCustomerOrders(String customerId) {
    if (customerId.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    // Defer the initial notification to avoid setState-during-build
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());

    _customerOrdersSub?.cancel();
    _customerOrdersSub = OrderService.watchCustomerOrders(customerId).listen(
      (orders) {
        _customerOrders = orders;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load customer orders: $e';
        AppLogger.error('Customer orders watch error: $e', tag: 'OrderProvider');
        notifyListeners();
      },
    );
  }

  /// Watch all orders for Admin panel (scoped by branchId if provided)
  void watchAdminOrders({String? status, String? branchId}) {
    _isLoading = true;
    _errorMessage = null;
    // Defer to avoid setState-during-build
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());

    _adminOrdersSub?.cancel();
    _adminOrdersSub = OrderService.watchAllOrders(status: status, branchId: branchId).listen(
      (orders) {
        _adminOrders = orders;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load orders: $e';
        AppLogger.error('Admin orders watch error: $e', tag: 'OrderProvider');
        notifyListeners();
      },
    );
  }

  /// Watch a specific order in real-time (for Customer Order Tracking)
  void watchOrder(String orderId) {
    if (orderId.isEmpty) return;
    _trackingSub?.cancel();
    _trackingSub = OrderService.watchOrder(orderId).listen(
      (order) {
        _currentOrder = order;
        notifyListeners();
      },
      onError: (e) {
        AppLogger.error('Order tracking watch error: $e', tag: 'OrderProvider');
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
    _customerOrdersSub?.cancel();
    _adminOrdersSub?.cancel();
    _trackingSub?.cancel();
    super.dispose();
  }
}
