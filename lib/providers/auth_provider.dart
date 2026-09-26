import 'package:flutter/material.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/services/firebase/firebase_auth_service.dart';
import 'package:food_fight/core/errors/app_exception.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Authentication state provider for role-based access & user session
class AuthProvider extends ChangeNotifier {
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

  /// Initialize auth state from Firebase on app launch
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser();
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
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during login';
      _setLoading(false);
      return false;
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
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during registration';
      _setLoading(false);
      return false;
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
        _setLoading(false);
        return false;
      }
      _currentUser = user;
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to sign in with Google';
      _setLoading(false);
      return false;
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
