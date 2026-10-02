import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_fight/models/coupon_model.dart';
import 'package:food_fight/services/coupon_service.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/utils/safe_change_notifier.dart';

/// Provider for managing Coupons in Admin and Customer checkout
class CouponProvider extends ChangeNotifier with SafeChangeNotifier {
  List<CouponModel> _coupons = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<CouponModel>>? _subscription;

  List<CouponModel> get coupons => List.unmodifiable(_coupons);
  List<CouponModel> get activeCoupons =>
      List.unmodifiable(_coupons.where((c) => c.isActive).toList());
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? _currentBranchId;

  String? get currentBranchId => _currentBranchId;

  CouponProvider() {
    init();
  }

  void init() {
    watchCoupons();
  }

  /// Real-time listener for coupons
  void watchCoupons({String? branchId}) {
    _currentBranchId = branchId;
    _isLoading = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    _subscription?.cancel();
    _subscription = CouponService.watchCoupons(branchId: branchId).listen(
      (data) {
        _coupons = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load coupons: $e';
        AppLogger.error('CouponProvider watch error: $e', tag: 'CouponProvider');
        notifyListeners();
      },
    );
  }

  /// Manual fetch
  Future<void> fetchCoupons({String? branchId}) async {
    _currentBranchId = branchId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _coupons = await CouponService.getCoupons(branchId: branchId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch coupons: $e';
      notifyListeners();
    }
  }

  /// Create coupon
  Future<bool> createCoupon(CouponModel coupon) async {
    try {
      await CouponService.createCoupon(coupon);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create coupon: $e';
      AppLogger.error('Create coupon error: $e', tag: 'CouponProvider');
      notifyListeners();
      return false;
    }
  }

  /// Update coupon
  Future<bool> updateCoupon(CouponModel coupon) async {
    try {
      await CouponService.updateCoupon(coupon);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update coupon: $e';
      AppLogger.error('Update coupon error: $e', tag: 'CouponProvider');
      notifyListeners();
      return false;
    }
  }

  /// Delete coupon
  Future<bool> deleteCoupon(String id) async {
    try {
      await CouponService.deleteCoupon(id);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete coupon: $e';
      AppLogger.error('Delete coupon error: $e', tag: 'CouponProvider');
      notifyListeners();
      return false;
    }
  }

  /// Toggle active status
  Future<bool> toggleActive(String id, bool currentStatus) async {
    try {
      await CouponService.toggleActive(id, currentStatus);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to toggle coupon: $e';
      AppLogger.error('Toggle coupon error: $e', tag: 'CouponProvider');
      notifyListeners();
      return false;
    }
  }

  /// Validate coupon for cart
  Future<CouponValidationResult> validateCoupon(
    String code,
    double subtotal, {
    String? branchId,
  }) async {
    return await CouponService.validateCoupon(
      code,
      subtotal,
      branchId: branchId ?? _currentBranchId,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
