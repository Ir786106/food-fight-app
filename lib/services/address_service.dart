import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';
import '../core/constants/firestore_collections.dart';
import '../core/utils/logger.dart';

class AddressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference _addressCol() {
    return _firestore.collection(FirestoreCollections.addresses);
  }

  /// Watch all delivery addresses for a given user
  static Stream<List<AddressModel>> watchAddresses(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _addressCol()
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AddressModel.fromJson(data);
      }).toList();

      // Sort default first, then newest first
      list.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      return list;
    });
  }

  /// Add a new delivery address
  static Future<AddressModel> addAddress(AddressModel address) async {
    try {
      final docRef = _addressCol().doc();
      final now = DateTime.now();

      // If set as default, clear other defaults first
      if (address.isDefault) {
        await _clearDefault(address.userId);
      }

      final toSave = address.copyWith(
        id: docRef.id,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(toSave.toJson());
      AppLogger.info('Address added: ${docRef.id}', tag: 'AddressService');
      return toSave;
    } catch (e) {
      AppLogger.error('Failed to add address: $e', tag: 'AddressService');
      rethrow;
    }
  }

  /// Update an existing delivery address
  static Future<void> updateAddress(AddressModel address) async {
    try {
      if (address.isDefault) {
        await _clearDefault(address.userId);
      }

      final data = address.copyWith(updatedAt: DateTime.now()).toJson();
      await _addressCol().doc(address.id).update(data);
      AppLogger.info('Address updated: ${address.id}', tag: 'AddressService');
    } catch (e) {
      AppLogger.error('Failed to update address: $e', tag: 'AddressService');
      rethrow;
    }
  }

  /// Delete a delivery address
  static Future<void> deleteAddress(String userId, String addressId) async {
    try {
      await _addressCol().doc(addressId).delete();
      AppLogger.info('Address deleted: $addressId', tag: 'AddressService');
    } catch (e) {
      AppLogger.error('Failed to delete address: $e', tag: 'AddressService');
      rethrow;
    }
  }

  /// Set an address as the default delivery address
  static Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      await _clearDefault(userId);
      await _addressCol().doc(addressId).update({
        'isDefault': 1,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      AppLogger.info('Set default address: $addressId', tag: 'AddressService');
    } catch (e) {
      AppLogger.error('Failed to set default address: $e', tag: 'AddressService');
      rethrow;
    }
  }

  static Future<void> _clearDefault(String userId) async {
    try {
      final snap = await _addressCol()
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: 1)
          .get();

      for (var doc in snap.docs) {
        await doc.reference.update({
          'isDefault': 0,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      AppLogger.error('Error clearing default addresses: $e', tag: 'AddressService');
    }
  }
}
