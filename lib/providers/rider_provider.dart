import 'dart:async';
import 'package:flutter/material.dart';
import '../models/rider_model.dart';
import '../models/order_model.dart';
import '../services/rider_service.dart';

class RiderProvider extends ChangeNotifier {
  List<RiderModel> _riders = [];
  List<OrderModel> _assignedDeliveries = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<RiderModel>>? _ridersSub;
  StreamSubscription<List<OrderModel>>? _deliveriesSub;

  List<RiderModel> get riders => List.unmodifiable(_riders);
  List<RiderModel> get activeRiders => _riders.where((r) => r.isActive).toList();
  List<RiderModel> get onlineRiders => _riders.where((r) => r.isActive && r.isOnline).toList();
  List<OrderModel> get assignedDeliveries => List.unmodifiable(_assignedDeliveries);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void watchAllRiders() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _ridersSub?.cancel();
    _ridersSub = RiderService.watchAllRiders().listen(
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

  void watchRiderDeliveries(String riderId) {
    if (riderId.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _deliveriesSub?.cancel();
    _deliveriesSub = RiderService.watchRiderDeliveries(riderId).listen(
      (orders) {
        _assignedDeliveries = orders;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load deliveries: $e';
        notifyListeners();
      },
    );
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
  }) async {
    try {
      await RiderService.assignRiderToOrder(
        orderId: orderId,
        riderId: riderId,
        riderName: riderName,
        riderPhone: riderPhone,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _ridersSub?.cancel();
    _deliveriesSub?.cancel();
    super.dispose();
  }
}
