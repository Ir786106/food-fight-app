import 'package:flutter/material.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/services/firebase/firebase_auth_service.dart';
import 'package:food_fight/services/fcm_service.dart';
import 'package:food_fight/core/errors/app_exception.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/utils/safe_change_notifier.dart';

/// Authentication state provider for role-based access & user session
class AuthProvider extends ChangeNotifier with SafeChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;
  bool get isAdmin => (_currentUser?.isAdmin ?? false) || isSuperAdmin;
  bool get isCustomer => _currentUser?.isCustomer ?? false;
  bool get isRider => _currentUser?.isRider ?? false;

  /// Initialize auth state from Firebase on app launch
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser();
      if (_currentUser != null) {
        FcmService.registerUserToken(_currentUser!.id);
      }
      AppLogger.info('Auth initialized: ${_currentUser?.email} (${_currentUser?.role})', tag: 'AuthProvider');
    } catch (e) {
      _currentUser = null;
      AppLogger.error('Auth initialization error: $e', tag: 'AuthProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign In with Email & Password
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.signIn(email: email, password: password);
      if (_currentUser != null) {
        FcmService.registerUserToken(_currentUser!.id);
      }
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = _parseError(e, 'Incorrect email or password, or account error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign Up with Email, Name, Phone & Password
  Future<bool> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.signUp(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      if (_currentUser != null) {
        FcmService.registerUserToken(_currentUser!.id);
      }
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = _parseError(e, 'An unexpected error occurred during registration. Please check your network and try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign In with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        // User cancelled the flow
        return false;
      }
      _currentUser = user;
      if (_currentUser != null) {
        FcmService.registerUserToken(_currentUser!.id);
      }
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = _parseError(e, 'Failed to complete Google sign-in. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error signing out: $e', tag: 'AuthProvider');
    }
  }

  /// Send password reset link
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send password reset email';
      _setLoading(false);
      return false;
    }
  }

  /// Alias for sendPasswordReset
  Future<bool> sendPasswordResetEmail(String email) => sendPasswordReset(email);

  /// Update Profile Details
  Future<bool> updateProfile({String? name, String? phone, String? profileImage}) async {
    _setLoading(true);
    try {
      await _authService.updateProfile(name: name, phone: phone, profileImage: profileImage);
      _currentUser = await _authService.getCurrentUser();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      _setLoading(false);
      return false;
    }
  }

  static String parseError(dynamic e, [String fallback = 'An unexpected error occurred. Please try again.']) {
    if (e == null) return fallback;
    if (e is AppException) return e.message;
    final str = e.toString().toLowerCase();
    if (str.contains('permission-denied')) {
      return "You don't have permission to perform this action.";
    }
    if (str.contains('timeout') || str.contains('timed out')) {
      return 'Request timed out after 20 seconds. Please check your internet connection.';
    }
    if (str.contains('network') || str.contains('unavailable') || str.contains('socketexception') || str.contains('network-request-failed')) {
      return 'Network connection failed. Please check your internet connection.';
    }
    if (str.contains('user-disabled')) {
      return 'This user account has been disabled. Please contact support.';
    }
    if (str.contains('invalid-credential') || str.contains('wrong-password') || str.contains('user-not-found')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (str.contains('typeerror') || str.contains('format') || str.contains('subtype')) {
      return 'Data parsing error occurred. Please contact support.';
    }
    return fallback;
  }

  String _parseError(dynamic e, String fallback) => parseError(e, fallback);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
