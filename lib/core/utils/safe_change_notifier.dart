import 'package:flutter/material.dart';

/// Mixin for [ChangeNotifier] that prevents `notifyListeners()` from being
/// dispatched after [dispose] has been called, and provides helper to defer
/// notifications to after the current frame to prevent `setState() during build`.
mixin SafeChangeNotifier on ChangeNotifier {
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  /// Safely schedule notifyListeners after the current build frame completes.
  void notifyListenersPostFrame() {
    if (_isDisposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        super.notifyListeners();
      }
    });
  }
}
