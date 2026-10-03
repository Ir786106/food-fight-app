import 'dart:async';
import 'package:flutter/material.dart';
import '../models/rider_model.dart';
import '../models/order_model.dart';
import '../services/rider_service.dart';
import '../core/utils/safe_change_notifier.dart';

class RiderProvider extends ChangeNotifier with SafeChangeNotifier {
  List<RiderModel> _riders = [];
  List<OrderModel> _assignedDeliveries = [];
  List<OrderModel> _completedDeliveries = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<RiderModel>>? _ridersSub;
  StreamSubscription<List<OrderModel>>? _deliveriesSub;
  StreamSubscription<List<OrderModel>>? _historySub;

  List<RiderModel> get riders => List.unmodifiable(_riders);
  List<RiderModel> get activeRiders => _riders.where((r) => r.isActive).toList();
  List<RiderModel> get onlineRiders => _riders.where((r) => r.isActive && r.isOnline).toList();
  List<OrderModel> get assignedDeliveries => List.unmodifiable(_assignedDeliveries);
  List<OrderModel> get completedDeliveries => List.unmodifiable(_completedDeliveries);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void watchAllRiders() {
    _isLoading = true;
    _errorMessage = null;
    notifyListenersPostFrame();

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

  void watchRiderDeliveries(String riderId, {String? riderPhone}) {
    if (riderId.isEmpty && (riderPhone == null || riderPhone.isEmpty)) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    _deliveriesSub?.cancel();
    _deliveriesSub = RiderService.watchRiderDeliveries(riderId, riderPhone: riderPhone).listen(
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

    _historySub?.cancel();
    _historySub = RiderService.watchRiderHistory(riderId, riderPhone: riderPhone).listen(
      (history) {
        _completedDeliveries = history;
        notifyListeners();
      },
      onError: (_) {},
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

  Future<bool> createRiderWithAuth({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? vehicleType,
    String? vehicleNumber,
  }) async {
    try {
      await RiderService.createRiderWithAuth(
        name: name,
        email: email,
        password: password,
        phone: phone,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
      );
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
    _historySub?.cancel();
    super.dispose();
  }
}
