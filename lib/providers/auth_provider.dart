import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/services/firebase/firebase_auth_service.dart';
import 'package:food_fight/services/fcm_service.dart';
import 'package:food_fight/core/errors/app_exception.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/utils/safe_change_notifier.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';

/// Authentication state provider for role-based access & user session
class AuthProvider extends ChangeNotifier with SafeChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

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

  /// Initialize auth state from Firebase on app launch with fast cache preference
  Future<void> init({bool preferCache = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser(preferCache: preferCache);
      if (_currentUser != null) {
        FcmService.registerUserToken(_currentUser!.id);
        _listenToUserDoc(_currentUser!.id);
        // Refresh from server in background to ensure up-to-date role
        unawaited(_refreshFromServerAsync(_currentUser!.id));
      }
      AppLogger.info('Auth initialized: ${_currentUser?.email} (${_currentUser?.role})', tag: 'AuthProvider');
    } catch (e) {
      AppLogger.error('Auth initialization error: $e', tag: 'AuthProvider');
      try {
        _currentUser = await _authService.getCurrentUser(preferCache: true);
        if (_currentUser != null) {
          FcmService.registerUserToken(_currentUser!.id);
          _listenToUserDoc(_currentUser!.id);
          unawaited(_refreshFromServerAsync(_currentUser!.id));
        }
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listen to user's own users/{uid} document for live role updates and deactivation
  void _listenToUserDoc(String uid) {
    _userDocSubscription?.cancel();
    _userDocSubscription = FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return;
        final data = snapshot.data()!;
        data['id'] = uid;
        final updatedUser = UserModel.fromJson(data);

        // Live deactivation: immediately sign out deactivated user
        if (!updatedUser.isActive) {
          AppLogger.warn('User ${updatedUser.id} deactivated in real-time. Signing out.', tag: 'AuthProvider');
          signOut();
          _errorMessage = 'Your account has been deactivated by administrator.';
          notifyListeners();
          return;
        }

        // Live role change: update currentUser and cache
        final roleChanged = updatedUser.role != _currentUser?.role;
        _currentUser = updatedUser;
        FirebaseAuthService.cacheRoleLocally(uid, updatedUser.role);

        if (roleChanged) {
          AppLogger.info('Live role changed for $uid: ${updatedUser.role}', tag: 'AuthProvider');
        }
        notifyListeners();
      },
      onError: (e) {
        AppLogger.warn('Error in user doc snapshot listener: $e', tag: 'AuthProvider');
      },
    );
  }

  /// Background refresh from server to ensure fresh profile data
  Future<void> _refreshFromServerAsync(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = uid;
        final freshUser = UserModel.fromJson(data);
        if (!freshUser.isActive) {
          await signOut();
          _errorMessage = 'Your account has been deactivated by administrator.';
          notifyListeners();
          return;
        }

        if (freshUser.role != _currentUser?.role ||
            freshUser.name != _currentUser?.name ||
            freshUser.profileImage != _currentUser?.profileImage) {
          _currentUser = freshUser;
          await FirebaseAuthService.cacheRoleLocally(uid, freshUser.role);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Sign In with Email & Password
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.signIn(email: email, password: password);
      if (_currentUser != null) {
        FcmService.registerUserToken(_currentUser!.id);
        _listenToUserDoc(_currentUser!.id);
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
        _listenToUserDoc(_currentUser!.id);
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
      FcmService.registerUserToken(_currentUser!.id);
      _listenToUserDoc(_currentUser!.id);
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
      _userDocSubscription?.cancel();
      _userDocSubscription = null;
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
    if (str.contains('profile-missing') || str.contains('profile not found')) {
      return 'Account profile not found, contact admin.';
    }
    if (str.contains('profile-unavailable')) {
      return 'Could not load your account profile. Please check your connection and retry or sign out.';
    }
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

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    super.dispose();
  }
}
