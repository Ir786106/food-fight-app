import 'package:food_fight/models/delivery_area_model.dart';

/// Interface for delivery area service
abstract class IDeliveryAreaService {
  /// Get all delivery areas
  Future<List<DeliveryAreaModel>> getAllDeliveryAreas();

  /// Get delivery area by ID
  Future<DeliveryAreaModel?> getDeliveryAreaById(String areaId);

  /// Get delivery area by name
  Future<DeliveryAreaModel?> getDeliveryAreaByName(String name);

  /// Get delivery areas by restaurant
  Future<List<DeliveryAreaModel>> getDeliveryAreasByRestaurant(String restaurantId);

  /// Create delivery area
  Future<DeliveryAreaModel?> createDeliveryArea(DeliveryAreaModel area);

  /// Update delivery area
  Future<void> updateDeliveryArea(DeliveryAreaModel area);

  /// Delete delivery area
  Future<void> deleteDeliveryArea(String areaId);

  /// Calculate delivery charge
  Future<double> getDeliveryCharge(String areaId, double orderTotal);
}
