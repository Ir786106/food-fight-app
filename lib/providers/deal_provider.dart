import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/safe_change_notifier.dart';
import '../models/deal_model.dart';
import '../services/deal_service.dart';

class DealProvider extends ChangeNotifier with SafeChangeNotifier {
  final DealService _dealService;

  DealProvider({DealService? dealService})
      : _dealService = dealService ?? DealService();

  List<DealModel> _deals = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<DealModel>>? _subscription;
  String? _currentBranchId;
  bool _activeOnly = false;
  String? _loadError;

  List<DealModel> get deals => _deals;
  List<DealModel> get activeDeals => _deals.where((d) => d.isValidNow).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get loadError => _loadError;

  void refreshDeals() {
    _subscription?.cancel();
    _subscription = null;
    watchDeals(branchId: _currentBranchId, activeOnly: _activeOnly);
  }

  /// Start watching deals for a specific branch (or all if null)
  void watchDeals({String? branchId, bool activeOnly = false}) {
    if (_currentBranchId == branchId &&
        _activeOnly == activeOnly &&
        _subscription != null) {
      return;
    }
    _deals = [];
    _currentBranchId = branchId;
    _activeOnly = activeOnly;
    _isLoading = true;
    _error = null;
    _loadError = null;
    notifyListenersPostFrame();

    _subscription?.cancel();
    _subscription = _dealService
        .streamDeals(branchId: branchId, activeOnly: activeOnly)
        .listen(
      (data) {
        _deals = data;
        _isLoading = false;
        _error = null;
        _loadError = null;
        notifyListenersPostFrame();
      },
      onError: (err) {
        _isLoading = false;
        _error = err.toString();
        _loadError = 'Unable to load deals. Please try again.';
        notifyListenersPostFrame();
      },
    );
  }

  /// Create a deal
  Future<bool> createDeal(DealModel deal) async {
    try {
      _isLoading = true;
      notifyListenersPostFrame();
      await _dealService.createDeal(deal);
      _isLoading = false;
      notifyListenersPostFrame();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListenersPostFrame();
      return false;
    }
  }

  /// Update a deal
  Future<bool> updateDeal(DealModel deal) async {
    try {
      _isLoading = true;
      notifyListenersPostFrame();
      await _dealService.updateDeal(deal);
      _isLoading = false;
      notifyListenersPostFrame();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListenersPostFrame();
      return false;
    }
  }

  /// Delete a deal
  Future<bool> deleteDeal(String dealId) async {
    try {
      await _dealService.deleteDeal(dealId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListenersPostFrame();
      return false;
    }
  }

  /// Toggle active state
  Future<void> toggleStatus(String dealId, bool isActive) async {
    try {
      await _dealService.toggleStatus(dealId, isActive);
    } catch (e) {
      _error = e.toString();
      notifyListenersPostFrame();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
