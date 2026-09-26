import 'package:food_fight/models/order_model.dart';

/// Interface for order service
abstract class IOrderService {
  /// Get all orders for user
  Future<List<OrderModel>> getUserOrders(String userId);

  /// Get order by ID
  Future<OrderModel?> getOrderById(String orderId);

  /// Create new order
  Future<OrderModel?> createOrder(OrderModel order);

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status);

  /// Cancel order
  Future<void> cancelOrder(String orderId, String reason);

  /// Get orders by status
  Future<List<OrderModel>> getOrdersByStatus(String userId, String status);

  /// Get pending orders
  Future<List<OrderModel>> getPendingOrders(String userId);

  /// Get active orders (out for delivery)
  Future<List<OrderModel>> getActiveOrders(String userId);

  /// Assign rider to order
  Future<void> assignRider(String orderId, String riderId);

  /// Remove rider from order
  Future<void> removeRider(String orderId);

  /// Get orders by rider
  Future<List<OrderModel>> getRiderOrders(String riderId);

  /// Track order status
  Future<void> trackOrder(String orderId);
}
