import 'dart:async';
import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';
import '../services/payment_method_service.dart';
import '../core/utils/safe_change_notifier.dart';

class PaymentMethodProvider extends ChangeNotifier with SafeChangeNotifier {
  List<PaymentMethodModel> _methods = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<PaymentMethodModel>>? _sub;

  List<PaymentMethodModel> get methods => List.unmodifiable(_methods);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PaymentMethodModel? get defaultMethod {
    final matches = _methods.where((m) => m.isDefault);
    return matches.isNotEmpty ? matches.first : (_methods.isNotEmpty ? _methods.first : null);
  }

  void watchMethods(String userId) {
    if (userId.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    _sub?.cancel();
    _sub = PaymentMethodService.watchPaymentMethods(userId).listen(
      (items) {
        _methods = items;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load payment methods: $e';
        notifyListeners();
      },
    );
  }

  Future<bool> addMethod(PaymentMethodModel method) async {
    try {
      await PaymentMethodService.addPaymentMethod(method);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMethod(String userId, String methodId) async {
    try {
      await PaymentMethodService.deletePaymentMethod(userId, methodId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefault(String userId, String methodId) async {
    try {
      await PaymentMethodService.setDefaultMethod(userId, methodId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
