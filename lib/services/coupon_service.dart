import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/coupon_model.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Coupon validation result
class CouponValidationResult {
  final bool isValid;
  final String? errorMessage;
  final double discountAmount;
  final CouponModel? coupon;
  final bool isFreeDelivery;

  CouponValidationResult({
    required this.isValid,
    this.errorMessage,
    this.discountAmount = 0.0,
    this.coupon,
    this.isFreeDelivery = false,
  });
}

/// Coupon Management Service (Firestore backed)
class CouponService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection(FirestoreCollections.coupons);

  /// Watch all coupons (Admin)
  static Stream<List<CouponModel>> watchCoupons() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CouponModel.fromJson(data);
      }).toList();
    });
  }

  /// Get all coupons
  static Future<List<CouponModel>> getCoupons() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CouponModel.fromJson(data);
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching coupons: $e', tag: 'CouponService');
      return [];
    }
  }

  /// Create new coupon
  static Future<String> createCoupon(CouponModel coupon) async {
    final docRef = _collection.doc();
    final data = coupon.toJson();
    data['id'] = docRef.id;
    data['code'] = coupon.code.toUpperCase().trim();
    await docRef.set(data);
    AppLogger.info('Created coupon: ${coupon.code}', tag: 'CouponService');
    return docRef.id;
  }

  /// Update coupon
  static Future<void> updateCoupon(CouponModel coupon) async {
    final data = coupon.toJson();
    data['code'] = coupon.code.toUpperCase().trim();
    await _collection.doc(coupon.id).update(data);
    AppLogger.info('Updated coupon: ${coupon.id}', tag: 'CouponService');
  }

  /// Delete coupon
  static Future<void> deleteCoupon(String id) async {
    await _collection.doc(id).delete();
    AppLogger.info('Deleted coupon: $id', tag: 'CouponService');
  }

  /// Toggle coupon active status
  static Future<void> toggleActive(String id, bool currentStatus) async {
    await _collection.doc(id).update({
      'isActive': currentStatus ? 0 : 1,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Validate coupon code during customer checkout
  static Future<CouponValidationResult> validateCoupon(String code, double subtotal) async {
    try {
      final cleanCode = code.toUpperCase().trim();
      final snapshot = await _collection.where('code', isEqualTo: cleanCode).limit(1).get();

      if (snapshot.docs.isEmpty) {
        return CouponValidationResult(isValid: false, errorMessage: 'Invalid coupon code');
      }

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      final coupon = CouponModel.fromJson(data);

      if (!coupon.isActive) {
        return CouponValidationResult(isValid: false, errorMessage: 'This coupon is no longer active');
      }

      final now = DateTime.now();
      if (now.isBefore(coupon.validFrom)) {
        return CouponValidationResult(isValid: false, errorMessage: 'This coupon is not valid yet');
      }
      if (now.isAfter(coupon.validUntil)) {
        return CouponValidationResult(isValid: false, errorMessage: 'This coupon has expired');
      }

      if (coupon.usageLimit > 0 && coupon.usageCount >= coupon.usageLimit) {
        return CouponValidationResult(isValid: false, errorMessage: 'Coupon usage limit has been reached');
      }

      if (subtotal < coupon.minimumOrder) {
        return CouponValidationResult(
          isValid: false,
          errorMessage: 'Minimum order amount is Rs. ${coupon.minimumOrder.toStringAsFixed(0)}',
        );
      }

      double discount = 0;
      bool isFreeDelivery = false;

      if (coupon.type == 'free_delivery') {
        isFreeDelivery = true;
      } else if (coupon.type == 'percentage') {
        discount = (subtotal * coupon.value) / 100.0;
        if (coupon.maximumDiscount != null && coupon.maximumDiscount! > 0) {
          if (discount > coupon.maximumDiscount!) {
            discount = coupon.maximumDiscount!;
          }
        }
      } else {
        // Flat discount
        discount = coupon.value;
        if (discount > subtotal) {
          discount = subtotal;
        }
      }

      return CouponValidationResult(
        isValid: true,
        discountAmount: discount,
        coupon: coupon,
        isFreeDelivery: isFreeDelivery,
      );
    } catch (e) {
      AppLogger.error('Error validating coupon: $e', tag: 'CouponService');
      return CouponValidationResult(isValid: false, errorMessage: 'Failed to apply coupon');
    }
  }
}
