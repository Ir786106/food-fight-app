import 'dart:async';
import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';
import '../core/utils/safe_change_notifier.dart';

class RestaurantProvider extends ChangeNotifier with SafeChangeNotifier {
  List<RestaurantModel> _restaurants = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<RestaurantModel>>? _sub;

  List<RestaurantModel> get restaurants => List.unmodifiable(_restaurants);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  RestaurantProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListenersPostFrame();

    try {
      await RestaurantService.ensureSeeded();
    } catch (_) {}

    _sub = RestaurantService.watchRestaurants().listen(
      (list) {
        _restaurants = list;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load restaurants: $e';
        notifyListeners();
      },
    );
  }

  RestaurantModel? getRestaurantById(String id) {
    final matches = _restaurants.where((r) => r.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
