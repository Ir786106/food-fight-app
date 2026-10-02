import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/safe_change_notifier.dart';
import '../models/loyalty_model.dart';
import '../services/loyalty_service.dart';

class LoyaltyProvider extends ChangeNotifier with SafeChangeNotifier {
  final LoyaltyService _loyaltyService;

  LoyaltyProvider({LoyaltyService? loyaltyService})
      : _loyaltyService = loyaltyService ?? LoyaltyService();

  LoyaltyAccount? _account;
  List<LoyaltyTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<LoyaltyAccount?>? _accountSub;
  StreamSubscription<List<LoyaltyTransaction>>? _txSub;
  String? _currentUserId;

  // Configurable rates (1 token = Rs 1, earn 1 token per Rs 100 spent)
  double tokenValueInCurrency = 1.0;
  int earnRateInCurrency = 100;

  LoyaltyAccount? get account => _account;
  List<LoyaltyTransaction> get transactions => _transactions;
  int get balance => _account?.balance ?? 0;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Start watching loyalty account & transactions for logged in customer
  void watchAccount(String userId) {
    if (userId.isEmpty) {
      _account = null;
      _transactions = [];
      notifyListenersPostFrame();
      return;
    }

    if (_currentUserId == userId && _accountSub != null) return;
    _currentUserId = userId;
    _isLoading = true;
    notifyListenersPostFrame();

    _accountSub?.cancel();
    _accountSub = _loyaltyService.streamAccount(userId).listen(
      (acc) {
        _account = acc;
        _isLoading = false;
        notifyListenersPostFrame();
      },
      onError: (err) {
        _isLoading = false;
        _error = err.toString();
        notifyListenersPostFrame();
      },
    );

    _txSub?.cancel();
    _txSub = _loyaltyService.streamTransactions(userId).listen(
      (txs) {
        _transactions = txs;
        notifyListenersPostFrame();
      },
      onError: (err) {
        _error = err.toString();
        notifyListenersPostFrame();
      },
    );
  }

  /// Credit welcome bonus
  Future<void> creditWelcomeBonus(String userId, {int amount = 50}) async {
    await _loyaltyService.creditWelcomeBonus(userId, amount: amount);
  }

  /// Redeem tokens during checkout
  Future<bool> redeemTokens({
    required String userId,
    required int tokensToRedeem,
    required String orderId,
  }) async {
    try {
      _isLoading = true;
      notifyListenersPostFrame();
      final ok = await _loyaltyService.redeemTokens(
        userId: userId,
        tokensToRedeem: tokensToRedeem,
        orderId: orderId,
      );
      _isLoading = false;
      notifyListenersPostFrame();
      return ok;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListenersPostFrame();
      return false;
    }
  }

  /// Earn tokens upon order delivery
  Future<void> earnTokensForOrder({
    required String userId,
    required String orderId,
    required double orderAmount,
  }) async {
    await _loyaltyService.earnTokensForOrder(
      userId: userId,
      orderId: orderId,
      orderAmount: orderAmount,
      earnRate: earnRateInCurrency,
    );
  }

  /// Refund tokens if an order is cancelled
  Future<void> refundTokensForCancelledOrder({
    required String userId,
    required String orderId,
    required int tokensToRefund,
  }) async {
    await _loyaltyService.refundTokensForCancelledOrder(
      userId: userId,
      orderId: orderId,
      tokensToRefund: tokensToRefund,
    );
  }

  @override
  void dispose() {
    _accountSub?.cancel();
    _txSub?.cancel();
    super.dispose();
  }
}
