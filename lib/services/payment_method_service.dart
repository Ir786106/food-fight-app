import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_method_model.dart';
import '../core/utils/logger.dart';

class PaymentMethodService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference _userMethods(String userId) {
    return _firestore.collection('users').doc(userId).collection('payment_methods');
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

  /// Save tokenized payment method (NEVER stores raw card/CVV)
  static Future<void> addPaymentMethod(PaymentMethodModel method) async {
    try {
      final docRef = _userMethods(method.userId).doc();
      final data = method.toJson();
      data['id'] = docRef.id;

      // If this method is set as default, remove default from others
      if (method.isDefault) {
        await _clearDefault(method.userId);
      }

      await docRef.set(data);
      AppLogger.info('Saved tokenized payment method ${docRef.id}', tag: 'PaymentService');
    } catch (e) {
      AppLogger.error('Failed to save payment method: $e', tag: 'PaymentService');
      rethrow;
    }
  }

  /// Remove payment method
  static Future<void> deletePaymentMethod(String userId, String methodId) async {
    try {
      await _userMethods(userId).doc(methodId).delete();
      AppLogger.info('Deleted payment method $methodId', tag: 'PaymentService');
    } catch (e) {
      AppLogger.error('Failed to delete payment method: $e', tag: 'PaymentService');
      rethrow;
    }
  }

  /// Set method as default
  static Future<void> setDefaultMethod(String userId, String methodId) async {
    try {
      await _clearDefault(userId);
      await _userMethods(userId).doc(methodId).update({'isDefault': 1});
    } catch (e) {
      AppLogger.error('Failed to set default method: $e', tag: 'PaymentService');
      rethrow;
    }
  }

  static Future<void> _clearDefault(String userId) async {
    final existing = await _userMethods(userId).where('isDefault', isEqualTo: 1).get();
    for (var doc in existing.docs) {
      await doc.reference.update({'isDefault': 0});
    }
  }
}
