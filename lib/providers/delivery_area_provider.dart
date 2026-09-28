import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_fight/models/delivery_area_model.dart';
import 'package:food_fight/services/delivery_area_service.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Provider for managing delivery coverage areas & charges
class DeliveryAreaProvider extends ChangeNotifier {
  List<DeliveryAreaModel> _areas = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<DeliveryAreaModel>>? _subscription;

  List<DeliveryAreaModel> get areas => List.unmodifiable(_areas);
  List<DeliveryAreaModel> get activeAreas =>
      List.unmodifiable(_areas.where((a) => a.isActive).toList());
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? _currentBranchId;

  String? get currentBranchId => _currentBranchId;

  DeliveryAreaProvider() {
    init();
  }

  void init() {
    watchAreas();
  }

  /// Watch real-time delivery areas
  void watchAreas({bool activeOnly = false, String? branchId}) {
    _currentBranchId = branchId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = DeliveryAreaService.watchDeliveryAreas(
      activeOnly: activeOnly,
      branchId: branchId,
    ).listen(
      (data) {
        _areas = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load delivery areas: $e';
        AppLogger.error('DeliveryAreaProvider watch error: $e', tag: 'DeliveryAreaProvider');
        notifyListeners();
      },
    );
  }

  /// Fetch areas manually
  Future<void> fetchAreas({bool activeOnly = false, String? branchId}) async {
    _currentBranchId = branchId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _areas = await DeliveryAreaService.getDeliveryAreas(
        activeOnly: activeOnly,
        branchId: branchId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch delivery areas: $e';
      notifyListeners();
    }
  }

  /// Create area
  Future<bool> createArea(DeliveryAreaModel area) async {
    try {
      await DeliveryAreaService.createDeliveryArea(area);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create delivery area: $e';
      AppLogger.error('Create delivery area error: $e', tag: 'DeliveryAreaProvider');
      notifyListeners();
      return false;
    }
  }

  /// Update area
  Future<bool> updateArea(DeliveryAreaModel area) async {
    try {
      await DeliveryAreaService.updateDeliveryArea(area);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update delivery area: $e';
      AppLogger.error('Update delivery area error: $e', tag: 'DeliveryAreaProvider');
      notifyListeners();
      return false;
    }
  }

  /// Delete area
  Future<bool> deleteArea(String id) async {
    try {
      await DeliveryAreaService.deleteDeliveryArea(id);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete delivery area: $e';
      AppLogger.error('Delete delivery area error: $e', tag: 'DeliveryAreaProvider');
      notifyListeners();
      return false;
    }
  }

  /// Toggle active
  Future<bool> toggleActive(String id, bool currentStatus) async {
    try {
      await DeliveryAreaService.toggleActive(id, currentStatus);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to toggle delivery area: $e';
      AppLogger.error('Toggle delivery area error: $e', tag: 'DeliveryAreaProvider');
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
