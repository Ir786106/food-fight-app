import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_method_model.dart';
import 'default_selection_service.dart';

class PaymentMethodService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference _userMethods(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods');
  }

  /// Watch saved payment methods for a customer
  static Stream<List<PaymentMethodModel>> watchPaymentMethods(String userId) {
    return _userMethods(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return PaymentMethodModel.fromJson(data);
      }).toList();
    });
  }


  static Future<void> addPaymentMethod(PaymentMethodModel method) async {
    if (!['jazzcash', 'easypaisa'].contains(method.type)) throw StateError('Only wallet references can be saved.');
    final id = method.id.isEmpty ? _userMethods(method.userId).doc().id : method.id;
    await DefaultSelectionService.write(userId: method.userId, collection: _userMethods(method.userId),
      pointer: 'defaultPaymentMethodId', id: id, data: {...method.toJson(), 'id': id}, select: method.isDefault);
  }
  static Future<void> deletePaymentMethod(String userId, String methodId) => DefaultSelectionService.write(
    userId: userId, collection: _userMethods(userId), pointer: 'defaultPaymentMethodId', id: methodId, delete: true);
  static Future<void> setDefaultMethod(String userId, String methodId) => DefaultSelectionService.write(
    userId: userId, collection: _userMethods(userId), pointer: 'defaultPaymentMethodId', id: methodId, select: true);
}
