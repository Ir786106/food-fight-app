import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';
import '../models/loyalty_model.dart';

class LoyaltyService {
  final FirebaseFirestore? _customFirestore;
  LoyaltyService({FirebaseFirestore? firestore}) : _customFirestore = firestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _accountsRef =>
      _firestore.collection('loyaltyAccounts');

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection('loyaltyTransactions');

  /// Stream a customer's loyalty account
  Stream<LoyaltyAccount?> streamAccount(String userId) {
    if (userId.isEmpty) return Stream.value(null);
    try {
      return _accountsRef.doc(userId).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) {
          return LoyaltyAccount(
            userId: userId,
            balance: 0,
            totalEarned: 0,
            totalRedeemed: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
        return LoyaltyAccount.fromJson(doc.data()!);
      });
    } catch (e) {
      AppLogger.error('Error streaming loyalty account: $e', tag: 'LoyaltyService');
      return Stream.value(null);
    }
  }

  /// Stream a customer's transaction history
  Stream<List<LoyaltyTransaction>> streamTransactions(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    try {
      return _transactionsRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return LoyaltyTransaction.fromJson(data);
        }).toList();
      });
    } catch (e) {
      AppLogger.error('Error streaming loyalty transactions: $e', tag: 'LoyaltyService');
      return Stream.value(<LoyaltyTransaction>[]);
    }
  }

  /// Reward balances are owned by trusted server transactions.
  Future<void> creditWelcomeBonus(String userId, {int amount = 50}) async {
    if (userId.isEmpty) return;
    await FirebaseFunctions.instance.httpsCallable('claimWelcomeBonus').call();
  }
}
