import 'package:food_fight/models/rider_model.dart';
import 'package:food_fight/models/order_model.dart';

/// Interface for rider service
abstract class IRiderService {
  /// Get all riders
  Future<List<RiderModel>> getAllRiders();

  /// Get rider by ID
  Future<RiderModel?> getRiderById(String riderId);

  /// Get rider by user ID
  Future<RiderModel?> getRiderByUserId(String userId);

  /// Create rider
  Future<RiderModel?> createRider(RiderModel rider);

  /// Update rider
  Future<void> updateRider(RiderModel rider);

  /// Delete rider
  Future<void> deleteRider(String riderId);

  /// Update rider status
  Future<void> updateRiderStatus(String riderId, bool isOnline);

  /// Get available riders
  Future<List<RiderModel>> getAvailableRiders();

  /// Assign order to rider
  Future<void> assignOrder(String riderId, String orderId);

  /// Remove order from rider
  Future<void> removeOrder(String riderId, String orderId);

  /// Get rider's assigned orders
  Future<List<OrderModel>> getRiderAssignedOrders(String riderId);

  /// Get rider's completed orders
  Future<List<OrderModel>> getRiderCompletedOrders(String riderId);
}
