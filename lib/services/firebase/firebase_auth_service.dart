import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/services/interfaces/auth_service_interface.dart';
import 'package:food_fight/core/errors/app_exception.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/services/loyalty_service.dart';

/// Firebase Authentication Service Implementation
class FirebaseAuthService implements IAuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  @override
  Future<UserModel?> getCurrentUser({bool preferCache = true}) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;
      return await _getUserData(firebaseUser, preferCache: preferCache);
    } catch (e) {
      AppLogger.error('Error getting current user: $e', tag: 'FirebaseAuthService');
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        final cachedRole = await getCachedUserRole(firebaseUser.uid) ?? 'customer';
        return UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? (firebaseUser.email?.split('@').first ?? 'User'),
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          role: cachedRole,
          isActive: true,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      return null;
    }
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
        throw AppException(message: 'User creation failed: no credential returned');
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

      // Write user document to Cloud Firestore
      await _usersCollection
          .doc(user.id)
          .set(user.toJson())
          .timeout(const Duration(seconds: 15));
      AppLogger.info('User signed up and saved to Firestore: ${user.email}', tag: 'FirebaseAuthService');

      // Credit welcome tokens from global_settings
      try {
        final settingsDoc = await _firestore
            .collection('settings')
            .doc('global_settings')
            .get()
            .timeout(const Duration(seconds: 5));
        final bonus = (settingsDoc.data()?['welcomeTokens'] as num? ?? 50).toInt();
        final loyalty = LoyaltyService(firestore: _firestore);
        await loyalty.creditWelcomeBonus(user.id, amount: bonus);
      } catch (e) {
        AppLogger.warn('Could not credit welcome bonus on sign-up: $e', tag: 'FirebaseAuthService');
      }

      return user;
    } on TimeoutException catch (e) {
      AppLogger.error('Sign up timed out: $e', tag: 'FirebaseAuthService');
      throw AppException(message: 'Registration timed out. Please check your internet connection.');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign up failed: ${e.code} - ${e.message}', tag: 'FirebaseAuthService');
      throw _getFirebaseException(e);
    } on FirebaseException catch (e) {
      AppLogger.error('Firestore/Firebase error during sign up: ${e.code} - ${e.message}', tag: 'FirebaseAuthService');
      if (e.code == 'permission-denied') {
        throw AppException(message: 'Permission denied creating account profile. Please contact support.');
      }
      throw AppException(message: e.message ?? 'Firebase service error during registration.');
    } on AppException {
      rethrow;
    } on TypeError catch (e) {
      AppLogger.error('Type error during sign up: $e', tag: 'FirebaseAuthService');
      throw AppException(message: 'Invalid user document format during registration.');
    } catch (e) {
      AppLogger.error('Sign up error: $e', tag: 'FirebaseAuthService');
      throw AppException(message: 'Registration encountered an issue: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> signIn({
    required String email,
    required String password,
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

      final user = await _getUserData(firebaseUser);

      // Check if account has been deactivated by Admin
      if (!user.isActive) {
        await _auth.signOut();
        throw AppException(
          message: 'Your account has been deactivated by administrator. Please contact support.',
        );
      }

      AppLogger.info('User signed in: ${user.email} (Role: ${user.role})', tag: 'FirebaseAuthService');
      return user;
    } on TimeoutException catch (e) {
      AppLogger.error('Sign in timed out: $e', tag: 'FirebaseAuthService');
      throw AppException(message: 'Sign in timed out. Please check your internet connection.');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign in failed: ${e.code} - ${e.message}', tag: 'FirebaseAuthService');
      throw _getFirebaseException(e);
    } on FirebaseException catch (e) {
      AppLogger.error('Firestore/Firebase error during sign in: ${e.code} - ${e.message}', tag: 'FirebaseAuthService');
      if (e.code == 'permission-denied') {
        throw AppException(message: 'Permission denied accessing account profile. Please contact support.');
      }
      throw AppException(message: e.message ?? 'Firebase service error during sign in.');
    } on AppException {
      rethrow;
    } on TypeError catch (e) {
      AppLogger.error('Type error during sign in: $e', tag: 'FirebaseAuthService');
      throw AppException(message: 'Invalid user document format. Please contact support.');
    } catch (e) {
      AppLogger.error('Sign in error: $e', tag: 'FirebaseAuthService');
      throw AppException(message: 'An error occurred during login: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? '585587375994-h4ohhnrmellh0ooboa0gpdp9pq2v0m86.apps.googleusercontent.com'
            : null,
        serverClientId: '585587375994-h4ohhnrmellh0ooboa0gpdp9pq2v0m86.apps.googleusercontent.com',
      );

      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        AppLogger.error('Google sign-in client error: $e', tag: 'FirebaseAuthService');
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('service_missing') ||
            errStr.contains('service_version_update_required') ||
            errStr.contains('service_disabled') ||
            errStr.contains('api_unavailable') ||
            errStr.contains('12500')) {
          throw AppException(
            message: 'Google Play services is unavailable or outdated on this device. Please sign in with Email & Password or update Google Play services.',
          );
        }
        throw AppException(message: 'Google Sign-In was cancelled or encountered an issue. Please sign in with Email & Password.');
      }

      if (googleUser == null) {
        AppLogger.info('Google sign-in was cancelled by user', tag: 'FirebaseAuthService');
        return null;
      }

      GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        AppLogger.error('Google auth token retrieval failed: $e', tag: 'FirebaseAuthService');
        throw AppException(message: 'Failed to retrieve Google authentication token.');
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 20));
      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw AppException(message: 'Google authentication failed: no user returned');
      }

      // Fetch existing user record or create new users/{uid} document with default role 'customer'
      final user = await _getUserData(firebaseUser);

      // Check if account has been blocked by Admin
      if (!user.isActive) {
        await _auth.signOut();
        try {
          await googleSignIn.signOut();
        } catch (_) {}
        throw AppException(
          message: 'Your account has been deactivated by administrator. Please contact support.',
        );
      }

      AppLogger.info('User authenticated with Google: ${user.email} (Role: ${user.role})', tag: 'FirebaseAuthService');
      return user;
    } on TimeoutException catch (e) {
      AppLogger.error('Google sign-in timed out: $e', tag: 'FirebaseAuthService');
      throw AppException(message: 'Google sign-in timed out. Please check your internet connection.');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Google sign-in failed: ${e.code} - ${e.message}', tag: 'FirebaseAuthService');
      throw _getFirebaseException(e);
    } on FirebaseException catch (e) {
      AppLogger.error('Firestore/Firebase error during Google sign-in: ${e.code} - ${e.message}', tag: 'FirebaseAuthService');
      if (e.code == 'permission-denied') {
        throw AppException(message: 'Permission denied accessing account profile. Please contact support.');
      }
      throw AppException(message: e.message ?? 'Firebase service error during Google sign-in.');
    } on AppException {
      rethrow;
    } on TypeError catch (e) {
      AppLogger.error('Type error parsing Google user profile: $e', tag: 'FirebaseAuthService');
      throw AppException(message: 'Invalid user document format. Please contact support.');
    } catch (e) {
      AppLogger.error('Google sign-in error: $e', tag: 'FirebaseAuthService');
      throw AppException(message: 'Failed to complete Google sign-in: ${e.toString()}');
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
      AppLogger.info('Password reset email sent to: $email', tag: 'FirebaseAuthService');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Password reset failed: ${e.code} - ${e.message}', tag: 'FirebaseAuthService');
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

      await _usersCollection.doc(user.uid).set(updates, SetOptions(merge: true));
      AppLogger.info('Profile updated for: ${user.email}', tag: 'FirebaseAuthService');
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
      AppLogger.info('Account deleted for: ${user.email}', tag: 'FirebaseAuthService');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Account deletion failed: ${e.code} - ${e.message}', tag: 'FirebaseAuthService');
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
      AppLogger.info('Verification email sent to: ${user.email}', tag: 'FirebaseAuthService');
    } catch (e) {
      AppLogger.error('Email verification error: $e', tag: 'FirebaseAuthService');
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
      final user = _auth.currentUser;
      if (user == null) return null;
      final doc = await _usersCollection.doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['role'] as String? ?? 'customer';
      }
      return 'customer';
    } catch (e) {
      AppLogger.error('Error getting user role: $e', tag: 'FirebaseAuthService');
      return 'customer';
    }
  }

  /// Cache user role locally in SharedPreferences for instantaneous offline routing
  static Future<void> cacheRoleLocally(String uid, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ff_cached_role_$uid', role);
      await prefs.setString('ff_last_active_uid', uid);
    } catch (_) {}
  }

  /// Retrieve cached user role from SharedPreferences
  static Future<String?> getCachedUserRole(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('ff_cached_role_$uid');
    } catch (_) {
      return null;
    }
  }

  /// Helper method to get user data from Firestore cache/network or create fallback record
  Future<UserModel> _getUserData(User firebaseUser, {bool preferCache = true}) async {
    // 1. Try local Firestore cache first for instant (<10ms) frame rendering
    if (preferCache) {
      try {
        final cacheDoc = await _usersCollection
            .doc(firebaseUser.uid)
            .get(const GetOptions(source: Source.cache));

        if (cacheDoc.exists && cacheDoc.data() != null) {
          final data = cacheDoc.data() as Map<String, dynamic>;
          final rawRole = data['role']?.toString().trim();
          if (rawRole == null || rawRole.isEmpty) {
            data['role'] = 'customer';
          }
          final cachedUser = UserModel.fromJson(data);
          unawaited(cacheRoleLocally(firebaseUser.uid, cachedUser.role));
          // Refresh asynchronously in background without blocking startup
          unawaited(_refreshUserDoc(firebaseUser.uid));
          return cachedUser;
        }
      } catch (_) {
        // Cache miss or local database not populated yet, proceed to network
      }
    }

    // 2. Fetch from network with short 3s timeout
    try {
      final doc = await _usersCollection
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 3));

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final rawRole = data['role']?.toString().trim();
        if (rawRole == null || rawRole.isEmpty) {
          data['role'] = 'customer';
        }
        final user = UserModel.fromJson(data);
        unawaited(cacheRoleLocally(firebaseUser.uid, user.role));
        return user;
      }
    } catch (e) {
      AppLogger.warn('Firestore user fetch timed out or failed ($e), proceeding with cached fallback', tag: 'FirebaseAuthService');
    }

    final fallbackRole = await getCachedUserRole(firebaseUser.uid) ?? 'customer';

    // 3. Fallback user record (never treat authenticated user as logged out!)
    final newUser = UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? (firebaseUser.email?.split('@').first ?? 'User'),
      email: firebaseUser.email ?? '',
      phone: firebaseUser.phoneNumber ?? '',
      role: fallbackRole,
      isActive: true,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save initial record in background if missing
    try {
      unawaited(_usersCollection
          .doc(newUser.id)
          .set(newUser.toJson(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 5))
          .catchError((_) {}));
    } catch (_) {}

    return newUser;
  }

  Future<void> _refreshUserDoc(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get(const GetOptions(source: Source.server));
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final role = data['role']?.toString().trim() ?? 'customer';
        await cacheRoleLocally(uid, role);
      }
    } catch (_) {}
  }

  AppException _getFirebaseException(FirebaseAuthException e) {
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
        message = 'An account already exists with this email using a different sign-in method';
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
        message = e.message ?? 'Authentication error occurred';
    }

    return AppException(message: message, code: e.code);
  }
}
