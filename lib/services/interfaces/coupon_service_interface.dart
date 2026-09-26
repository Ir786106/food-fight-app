import 'package:food_fight/models/coupon_model.dart';

/// Interface for coupon service
abstract class ICouponService {
  /// Get all coupons
  Future<List<CouponModel>> getAllCoupons();

  /// Get coupon by code
  Future<CouponModel?> getCouponByCode(String code);

  /// Get active coupons
  Future<List<CouponModel>> getActiveCoupons();

  /// Get coupons by restaurant
  Future<List<CouponModel>> getCouponsByRestaurant(String restaurantId);

  /// Create coupon
  Future<CouponModel?> createCoupon(CouponModel coupon);

  /// Update coupon
  Future<void> updateCoupon(CouponModel coupon);

  /// Delete coupon
  Future<void> deleteCoupon(String couponId);

  /// Activate/deactivate coupon
  Future<void> setCouponStatus(String couponId, bool isActive);

  /// Validate coupon
  Future<CouponValidationResult> validateCoupon(
    String code,
    double orderTotal,
    String userId,
  );

  /// Increment coupon usage
  Future<void> incrementUsage(String couponId);
}

/// Result of coupon validation
class CouponValidationResult {
  final bool isValid;
  final double discountAmount;
  final String? message;

  CouponValidationResult({
    required this.isValid,
    required this.discountAmount,
    this.message,
  });

  factory CouponValidationResult.invalid(String message) {
    return CouponValidationResult(
      isValid: false,
      discountAmount: 0,
      message: message,
    );
  }

  factory CouponValidationResult.valid(double discount) {
    return CouponValidationResult(
      isValid: true,
      discountAmount: discount,
      message: null,
    );
  }
}
