import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/models/address_model.dart';

/// Interface for user service
abstract class IUserService {
  /// Get user by ID
  Future<UserModel?> getUserById(String userId);

  /// Get current user
  Future<UserModel?> getCurrentUser();

  /// Update user profile
  Future<void> updateProfile(UserModel user);

  /// Update user role
  Future<void> updateRole(String userId, String role);

  /// Update user status
  Future<void> updateStatus(String userId, bool isActive);

  /// Add address for user
  Future<void> addAddress(AddressModel address);

  /// Update address
  Future<void> updateAddress(AddressModel address);

  /// Delete address
  Future<void> deleteAddress(String addressId);

  /// Get user addresses
  Future<List<AddressModel>> getAddresses(String userId);

  /// Get default address
  Future<AddressModel?> getDefaultAddress(String userId);

  /// Set default address
  Future<void> setDefaultAddress(String addressId);
}
