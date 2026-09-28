import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/services/interfaces/auth_service_interface.dart';
import 'package:food_fight/core/errors/app_exception.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';

/// Firebase Authentication Service Implementation
class FirebaseAuthService implements IAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;
      return await _getUserData(firebaseUser);
    } catch (e) {
      AppLogger.error('Error getting current user: $e', tag: 'FirebaseAuthService');
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
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw AppException(message: 'User creation failed');
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
      await _usersCollection.doc(user.id).set(user.toJson());
      AppLogger.info('User signed up and saved to Firestore: ${user.email}', tag: 'FirebaseAuthService');

      return user;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign up failed: ${e.code} - ${e.message}', tag: 'FirebaseAuthService');
      throw _getFirebaseException(e);
    } catch (e) {
      AppLogger.error('Sign up error: $e', tag: 'FirebaseAuthService');
      throw AppException(message: e.toString());
    }
  }

  @override
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

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
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign in failed: ${e.code} - ${e.message}', tag: 'FirebaseAuthService');
      throw _getFirebaseException(e);
    } catch (e) {
      AppLogger.error('Sign in error: $e', tag: 'FirebaseAuthService');
      rethrow;
    }
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? '585587375994-h4ohhnrmellh0ooboa0gpdp9pq2v0m86.apps.googleusercontent.com'
            : null,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        AppLogger.info('Google sign-in was cancelled by user', tag: 'FirebaseAuthService');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
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
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Google sign-in failed: ${e.code} - ${e.message}', tag: 'FirebaseAuthService');
      throw _getFirebaseException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      AppLogger.error('Google sign-in error: $e', tag: 'FirebaseAuthService');
      throw AppException(message: 'Failed to complete Google sign-in. Please try again.');
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

  /// Helper method to get user data from Firestore or create initial record
  Future<UserModel> _getUserData(User firebaseUser) async {
    final doc = await _usersCollection.doc(firebaseUser.uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      return UserModel.fromJson(data);
    }

    // Default user record if not in Firestore yet
    final newUser = UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? (firebaseUser.email?.split('@').first ?? 'User'),
      email: firebaseUser.email ?? '',
      phone: '',
      role: 'customer',
      isActive: true,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _usersCollection.doc(newUser.id).set(newUser.toJson(), SetOptions(merge: true));
    return newUser;
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
