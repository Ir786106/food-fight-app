import 'package:food_fight/models/user_model.dart';

/// Interface for authentication service
abstract class IAuthService {
  /// Get current user
  Future<UserModel?> getCurrentUser();

  /// Check if user is logged in
  Future<bool> isLoggedIn();

  /// Sign up with email and password
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  /// Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  });

  /// Sign in or register with Google Authentication
  Future<UserModel?> signInWithGoogle();

  /// Sign in with email link
  Future<void> signInWithEmailLink(String email, String link);

  /// Sign out
  Future<void> signOut();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? profileImage,
  });

  /// Delete account
  Future<void> deleteAccount();

  /// Verify email
  Future<void> verifyEmail();

  /// Check if email is verified
  Future<bool> isEmailVerified();

  /// Get user role
  Future<String?> getUserRole();
}
