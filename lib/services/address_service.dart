import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';
import '../core/constants/firestore_collections.dart';
import 'default_selection_service.dart';

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


  static Future<AddressModel> addAddress(AddressModel address) async {
    final saved = address.copyWith(id: _addressCol().doc().id, createdAt: DateTime.now(), updatedAt: DateTime.now());
    await _write(saved);
    return saved;
  }
  static Future<void> updateAddress(AddressModel address) => _write(address.copyWith(updatedAt: DateTime.now()));
  static Future<void> _write(AddressModel address) => DefaultSelectionService.write(
    userId: address.userId, collection: _addressCol(), pointer: 'defaultAddressId',
    id: address.id, data: address.toJson(), select: address.isDefault);
  static Future<void> deleteAddress(String userId, String addressId) => DefaultSelectionService.write(
    userId: userId, collection: _addressCol(), pointer: 'defaultAddressId', id: addressId, delete: true);
  static Future<void> setDefaultAddress(String userId, String addressId) => DefaultSelectionService.write(
    userId: userId, collection: _addressCol(), pointer: 'defaultAddressId', id: addressId, select: true);
}
