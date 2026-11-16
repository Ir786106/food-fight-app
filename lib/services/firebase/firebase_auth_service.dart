import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/services/interfaces/auth_service_interface.dart';
import 'package:food_fight/core/errors/app_exception.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/services/loyalty_service.dart';

/// Firebase Authentication Service Implementation
/// Enforces strict role resolution, server-first sign-in verification,
/// and prevents customer fallback contamination for administrative roles.
class FirebaseAuthService implements IAuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  @override
  Future<UserModel?> getCurrentUser({bool preferCache = true}) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    if (preferCache) {
      try {
        final snapshot = await _usersCollection
            .doc(firebaseUser.uid)
            .get(const GetOptions(source: Source.cache));
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data != null &&
            data['role'] == 'customer' &&
            UserModel.isProfileActive(data)) {
          return validateSessionProfile(data, expectedUid: firebaseUser.uid);
        }
      } on FirebaseException {
        // A cache miss is resolved by reading the server.
      }
    }
    return _fetchUserFromServerWithRetry(firebaseUser);
  }

  Future<UserModel?> getVerifiedCurrentUser() async {
    final user = _auth.currentUser;
    return user == null ? null : _fetchUserFromServerWithRetry(user);
  }

  @override
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  @override
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(const Duration(seconds: 20));

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw AppException(
            message: 'User creation failed: no credential returned');
      }

      await firebaseUser.updateDisplayName(name);

      final user = UserModel(
        id: firebaseUser.uid,
        name: name,
        email: email.trim(),
        phone: phone.trim(),
        role: 'customer',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Explicit sign-up creates the initial customer document in Cloud Firestore
      await _usersCollection
          .doc(user.id)
          .set(user.toJson())
          .timeout(const Duration(seconds: 15));
      await cacheRoleLocally(user.id, user.role);

      AppLogger.info('User signed up and saved to Firestore: ${user.email}',
          tag: 'FirebaseAuthService');

      // Credit welcome tokens from global_settings
      try {
        final settingsDoc = await _firestore
            .collection('settings')
            .doc('global_settings')
            .get()
            .timeout(const Duration(seconds: 5));
        final bonus =
            (settingsDoc.data()?['welcomeTokens'] as num? ?? 50).toInt();
        final loyalty = LoyaltyService(firestore: _firestore);
        await loyalty.creditWelcomeBonus(user.id, amount: bonus);
      } catch (e) {
        AppLogger.warn('Could not credit welcome bonus on sign-up: $e',
            tag: 'FirebaseAuthService');
      }

      return user;
    } on TimeoutException catch (e) {
      AppLogger.error('Sign up timed out: $e', tag: 'FirebaseAuthService');
      throw AppException(
          message:
              'Registration timed out. Please check your internet connection.');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign up failed: ${e.code} - ${e.message}',
          tag: 'FirebaseAuthService');
      throw _getFirebaseException(e);
    } on FirebaseException catch (e) {
      AppLogger.error(
          'Firestore/Firebase error during sign up: ${e.code} - ${e.message}',
          tag: 'FirebaseAuthService');
      if (e.code == 'permission-denied') {
        throw AppException(
            message:
                'Permission denied creating account profile. Please contact support.');
      }
      throw AppException(
          message: e.message ?? 'Firebase service error during registration.');
    } on AppException {
      rethrow;
    } on TypeError catch (e) {
      AppLogger.error('Type error during sign up: $e',
          tag: 'FirebaseAuthService');
      throw AppException(
          message: 'Invalid user document format during registration.');
    } catch (e) {
      AppLogger.error('Sign up error: $e', tag: 'FirebaseAuthService');
      throw AppException(
          message: 'Registration encountered an issue: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> signIn({
    required String email,
    required String password,
    bool allowCachedRole = true,
  }) async {
    try {
      final credential = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(const Duration(seconds: 20));

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw AppException(message: 'Login failed: no user returned');
      }

      // Always read users/{uid} directly from the SERVER (12s timeout + 1 retry)
      final user = await _fetchUserFromServerWithRetry(firebaseUser);

      // Check if account has been deactivated by Admin
      if (!user.isActive) {
        await _auth.signOut();
        throw AppException(
          message:
              'Your account has been deactivated by administrator. Please contact support.',
        );
      }

      AppLogger.info('User signed in (role: ${user.role})',
          tag: 'FirebaseAuthService');
      return user;
    } on TimeoutException catch (e) {
      AppLogger.error('Sign in timed out: $e', tag: 'FirebaseAuthService');
      throw AppException(
          message: 'Sign in timed out. Please check your internet connection.');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign in failed (${e.code})', tag: 'FirebaseAuthService');
      throw _getFirebaseException(e);
    } on FirebaseException catch (e) {
      AppLogger.error(
          'Firestore/Firebase error during sign in: ${e.code} - ${e.message}',
          tag: 'FirebaseAuthService');
      if (e.code == 'permission-denied') {
        throw AppException(
            message:
                'Permission denied accessing account profile. Please contact support.');
      }
      throw AppException(
          message: 'Could not complete sign-in. Please try again.');
    } on AppException {
      rethrow;
    } on TypeError catch (e) {
      AppLogger.error('Type error during sign in: $e',
          tag: 'FirebaseAuthService');
      throw AppException(
          message: 'Invalid user document format. Please contact support.');
    } catch (e) {
      AppLogger.error('Sign in error: $e', tag: 'FirebaseAuthService');
      throw AppException(
          message: 'An error occurred during login. Please try again.');
    }
  }

  @override
  Future<UserModel?> signInWithGoogle({bool allowCachedRole = true}) async {
    try {
      final googleSignIn = kIsWeb ? null : GoogleSignIn();
      final UserCredential userCredential;
      if (googleSignIn == null) {
        userCredential = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        if (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux) {
          throw AppException(
              message: 'Use email and password to sign in on this device.');
        }
        final credential = await _googleCredential(googleSignIn);
        if (credential == null) return null;
        userCredential = await _auth
            .signInWithCredential(credential)
            .timeout(const Duration(seconds: 20));
      }

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw AppException(
            message: 'Google authentication failed: no user returned');
      }

      final UserModel user;
      try {
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          final ref = _usersCollection.doc(firebaseUser.uid);
          await _firestore.runTransaction((transaction) async {
            if ((await transaction.get(ref)).exists) return;
            final now = DateTime.now();
            transaction.set(
                ref,
                UserModel(
                  id: firebaseUser.uid,
                  name: firebaseUser.displayName ?? 'Customer',
                  email: firebaseUser.email ?? '',
                  phone: firebaseUser.phoneNumber ?? '',
                  role: 'customer',
                  isActive: true,
                  createdAt: now,
                  updatedAt: now,
                ).toJson());
          }).timeout(const Duration(seconds: 15));
        }
        user = await _fetchUserFromServerWithRetry(firebaseUser);
      } catch (_) {
        if (_auth.currentUser?.uid == firebaseUser.uid) await _auth.signOut();
        rethrow;
      }

      // Check if account has been blocked by Admin
      if (!user.isActive) {
        await _auth.signOut();
        try {
          await googleSignIn?.signOut();
        } catch (_) {}
        throw AppException(
          message:
              'Your account has been deactivated by administrator. Please contact support.',
        );
      }

      AppLogger.info('User authenticated with Google (role: ${user.role})',
          tag: 'FirebaseAuthService');
      return user;
    } on TimeoutException catch (e) {
      AppLogger.error('Google sign-in timed out: $e',
          tag: 'FirebaseAuthService');
      throw AppException(
          message:
              'Google sign-in timed out. Please check your internet connection.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return null;
      }
      AppLogger.error(
          'Firebase Google sign-in failed: ${e.code} - ${e.message}',
          tag: 'FirebaseAuthService');
      throw _getFirebaseException(e);
    } on FirebaseException catch (e) {
      AppLogger.error(
          'Firestore/Firebase error during Google sign-in: ${e.code} - ${e.message}',
          tag: 'FirebaseAuthService');
      if (e.code == 'permission-denied') {
        throw AppException(
            message:
                'Permission denied accessing account profile. Please contact support.');
      }
      throw AppException(
          message:
              'Could not load your Google account profile. Check your connection and retry.');
    } on AppException {
      rethrow;
    } on TypeError catch (e) {
      AppLogger.error('Type error parsing Google user profile: $e',
          tag: 'FirebaseAuthService');
      throw AppException(
          message: 'Invalid user document format. Please contact support.');
    } catch (e) {
      AppLogger.error('Google sign-in error: $e', tag: 'FirebaseAuthService');
      throw AppException(
          message: 'Failed to complete Google sign-in. Please try again.');
    }
  }

  Future<OAuthCredential?> _googleCredential(GoogleSignIn googleSignIn) async {
    GoogleSignInAccount? googleUser;
    try {
      googleUser = await googleSignIn.signIn();
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      // Silent handling for user cancellation
      if (errStr.contains('sign_in_canceled') ||
          errStr.contains('canceled') ||
          errStr.contains('cancelled') ||
          errStr.contains('12501')) {
        AppLogger.info('User cancelled Google Sign-In',
            tag: 'FirebaseAuthService');
        return null;
      }

      AppLogger.error('Google sign-in client error: $e',
          tag: 'FirebaseAuthService');
      if (RegExp(r'ApiException:\s*10\b', caseSensitive: false)
          .hasMatch(e.toString())) {
        throw AppException(
            message:
                'Google sign-in is unavailable for this app build. You can still sign in with email and password.');
      }
      if (errStr.contains('network_error') ||
          RegExp(r'ApiException:\s*7\b', caseSensitive: false)
              .hasMatch(e.toString())) {
        throw AppException(
            message:
                'Google sign-in could not connect. Check your internet connection and retry.');
      }
      if (errStr.contains('service_missing') ||
          errStr.contains('service_version_update_required') ||
          errStr.contains('service_disabled') ||
          errStr.contains('api_unavailable')) {
        throw AppException(
          message:
              'Google Play services is unavailable or outdated on this device. Please sign in with Email & Password or update Google Play services.',
        );
      }
      throw AppException(
          message:
              'Google Sign-In encountered an issue. Please try again or use Email & Password.');
    }

    if (googleUser == null) {
      AppLogger.info('Google sign-in was cancelled by user',
          tag: 'FirebaseAuthService');
      return null;
    }

    GoogleSignInAuthentication googleAuth;
    try {
      googleAuth = await googleUser.authentication;
    } catch (e) {
      AppLogger.error('Google auth token retrieval failed: $e',
          tag: 'FirebaseAuthService');
      throw AppException(
          message: 'Failed to retrieve Google authentication token.');
    }

    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  Future<UserModel> signInWithPhone(
    Future<UserCredential> Function(String) confirm,
    String code,
  ) async {
    final credential = await confirm(code);
    final user = credential.user;
    if (user == null) {
      throw AppException(message: 'Phone sign-in did not return an account.');
    }
    try {
      await FirebaseFunctions.instance
          .httpsCallable('completePhoneProfile')
          .call();
      final profile = await _fetchUserFromServerWithRetry(user);
      if (!profile.isActive || profile.role != 'customer') {
        throw AppException(
            message: 'This account cannot use customer phone sign-in.');
      }
      return profile;
    } on FirebaseFunctionsException catch (error) {
      await _auth.signOut();
      throw AppException(
          message: error.message ?? 'Could not verify your profile.');
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  @override
  Future<void> signInWithEmailLink(String email, String link) async {
    try {
      await _auth.signInWithEmailLink(email: email, emailLink: link);
    } catch (e) {
      throw AppException(message: 'Failed to sign in with email link');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      AppLogger.info('User signed out', tag: 'FirebaseAuthService');
    } catch (e) {
      AppLogger.error('Sign out error: $e', tag: 'FirebaseAuthService');
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      AppLogger.info('Password reset email sent to: $email',
          tag: 'FirebaseAuthService');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Password reset failed: ${e.code} - ${e.message}',
          tag: 'FirebaseAuthService');
      throw _getFirebaseException(e);
    } catch (e) {
      AppLogger.error('Password reset error: $e', tag: 'FirebaseAuthService');
      rethrow;
    }
  }

  @override
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw AppException(message: 'No user logged in');

      if (name != null && name.isNotEmpty) {
        await user.updateDisplayName(name);
      }

      final Map<String, dynamic> updates = {
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (profileImage != null) updates['profileImage'] = profileImage;

      await _usersCollection
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));
      AppLogger.info('Profile updated for: ${user.email}',
          tag: 'FirebaseAuthService');
    } catch (e) {
      AppLogger.error('Profile update error: $e', tag: 'FirebaseAuthService');
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw AppException(message: 'No user logged in');

      await _usersCollection.doc(user.uid).delete();
      await user.delete();
      AppLogger.info('Account deleted for: ${user.email}',
          tag: 'FirebaseAuthService');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Account deletion failed: ${e.code} - ${e.message}',
          tag: 'FirebaseAuthService');
      throw _getFirebaseException(e);
    } catch (e) {
      AppLogger.error('Account deletion error: $e', tag: 'FirebaseAuthService');
      rethrow;
    }
  }

  @override
  Future<void> verifyEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw AppException(message: 'No user logged in');

      await user.sendEmailVerification();
      AppLogger.info('Verification email sent to: ${user.email}',
          tag: 'FirebaseAuthService');
    } catch (e) {
      AppLogger.error('Email verification error: $e',
          tag: 'FirebaseAuthService');
      rethrow;
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return user.emailVerified;
  }

  @override
  Future<String?> getUserRole() async {
    try {
      return (await getVerifiedCurrentUser())?.role;
    } on AppException {
      return null;
    }
  }

  /// Cache user role locally in SharedPreferences for instantaneous offline routing
  static Future<void> cacheRoleLocally(String uid, String role) async {
    try {
      final normalized = UserRole.fromString(role).firestoreValue;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ff_cached_role_$uid', normalized);
      await prefs.setString('ff_last_active_uid', uid);
    } catch (_) {}
  }

  /// Retrieve cached user role from SharedPreferences
  static Future<String?> getCachedUserRole(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('ff_cached_role_$uid');
      if (stored == null || stored.isEmpty) return null;
      return UserRole.fromString(stored).firestoreValue;
    } catch (_) {
      return null;
    }
  }

  /// Reads users/{uid} directly from SERVER with 12s timeout and 1 retry.
  /// NEVER falls back to role 'customer' for existing users.
  /// NEVER writes a fallback document to Firestore.
  /// If doc is missing for an authenticated user, signs out and throws an exception.
  Future<UserModel> _fetchUserFromServerWithRetry(
    User firebaseUser,
  ) async {
    Exception? lastError;
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final doc = await _usersCollection
            .doc(firebaseUser.uid)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 12));
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          throw AppException(
            message: 'Account profile not found, contact admin',
            code: 'profile-missing',
          );
        }
        final user =
            validateSessionProfile(data, expectedUid: firebaseUser.uid);
        await cacheRoleLocally(firebaseUser.uid, user.role);
        return user;
      } on AppException {
        if (_auth.currentUser?.uid == firebaseUser.uid) await _auth.signOut();
        rethrow;
      } on FirebaseException catch (error) {
        if (error.code == 'permission-denied') {
          if (_auth.currentUser?.uid == firebaseUser.uid) await _auth.signOut();
          throw AppException(
            message:
                'Permission denied accessing account profile. Please contact support.',
            code: 'profile-permission-denied',
          );
        }
        lastError = error;
      } on TimeoutException catch (error) {
        lastError = error;
      } on TypeError {
        if (_auth.currentUser?.uid == firebaseUser.uid) await _auth.signOut();
        throw AppException(
          message: 'Invalid user document format. Please contact support.',
          code: 'profile-invalid',
        );
      }
      if (attempt == 1) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
    }
    throw ProfileUnavailableException(
      message:
          'Could not load your account profile. Please check your connection and retry or sign out.',
      originalException: lastError,
    );
  }

  static UserModel validateSessionProfile(
    Map<String, dynamic> data, {
    String? expectedUid,
  }) {
    if (!UserModel.isProfileActive(data)) {
      throw AppException(
        message:
            'Your account has been deactivated by administrator. Please contact support.',
        code: 'profile-disabled',
      );
    }
    final rawRole = data['role'];
    final role = UserRole.fromString(rawRole);
    if (role == UserRole.superAdmin &&
        expectedUid != null &&
        [data['id'], data['uid']]
            .any((id) => id != null && id != '' && id != expectedUid)) {
      throw AppException(
        message:
            'This account profile does not match your sign-in. Please contact support.',
        code: 'profile-uid-mismatch',
      );
    }
    if (role == UserRole.superAdmin && rawRole != UserModel.roleSuperAdmin) {
      throw AppException(
        message:
            'This Super Admin profile needs a role correction. Please contact support.',
        code: 'profile-role-migration-required',
      );
    }
    if (role == UserRole.unknown) {
      throw AppException(
        message:
            'This account has an unsupported role. Please contact support.',
        code: 'profile-role-invalid',
      );
    }
    return UserModel.fromJson(
        expectedUid == null ? data : {...data, 'id': expectedUid});
  }

  AppException _getFirebaseException(FirebaseAuthException e) => authError(e);

  static AppException authError(FirebaseAuthException e) {
    if (e.code == 'internal-error' &&
        (e.message ?? '').toLowerCase().contains('connection reset')) {
      return AppException(
        message: 'Network error. Please check your internet connection',
        code: 'network-request-failed',
      );
    }
    String message = 'Authentication failed';

    switch (e.code) {
      case 'invalid-email':
        message = 'Invalid email address format';
      case 'wrong-password':
      case 'invalid-credential':
        message = 'Incorrect email or password';
      case 'user-not-found':
        message = 'No account found with this email';
      case 'user-disabled':
        message = 'This account has been disabled';
      case 'too-many-requests':
        message = 'Too many attempts. Please try again in a few moments';
      case 'operation-not-allowed':
        message = 'Email/password sign-in is not enabled';
      case 'email-already-in-use':
        message = 'An account with this email already exists';
      case 'account-exists-with-different-credential':
        message =
            'An account already exists with this email using a different sign-in method';
      case 'credential-already-in-use':
        message = 'This Google account is already linked to another profile';
      case 'popup-closed-by-user':
      case 'sign_in_canceled':
        message = 'Google sign-in was cancelled';
      case 'network-request-failed':
        message = 'Network error. Please check your internet connection';
      case 'weak-password':
        message = 'The password provided is too weak (min 6 characters)';
      default:
        message = 'Authentication could not be completed. Please try again.';
    }

    return AppException(message: message, code: e.code);
  }
}
