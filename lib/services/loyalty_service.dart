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

  /// Credit welcome bonus upon user registration
  Future<void> creditWelcomeBonus(String userId, {int amount = 50}) async {
    if (userId.isEmpty || amount <= 0) return;

    final accountDoc = _accountsRef.doc(userId);
    final txDoc = _transactionsRef.doc();

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(accountDoc);

        // If account already exists and has bonus, do not double-credit
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && (data['hasWelcomeBonus'] == true || (data['totalEarned'] ?? 0) > 0)) {
            return; // Already received bonus
          }
        }

        final now = DateTime.now();
        final currentBalance = snapshot.exists ? (snapshot.data()?['balance'] as num? ?? 0).toInt() : 0;
        final newBalance = currentBalance + amount;

        transaction.set(
          accountDoc,
          {
            'userId': userId,
            'balance': newBalance,
            'totalEarned': amount,
            'totalRedeemed': 0,
            'hasWelcomeBonus': true,
            'createdAt': (snapshot.exists && snapshot.data() != null && snapshot.data()!['createdAt'] != null)
                ? snapshot.data()!['createdAt']
                : now.millisecondsSinceEpoch,
            'updatedAt': now.millisecondsSinceEpoch,
          },
          SetOptions(merge: true),
        );

        transaction.set(txDoc, {
          'userId': userId,
          'type': 'bonus',
          'amount': amount,
          'balanceAfter': newBalance,
          'description': 'Welcome to Food Fight bonus tokens! 🎁',
          'createdAt': now.millisecondsSinceEpoch,
        });
      });

      AppLogger.info('Welcome bonus of $amount credited to $userId', tag: 'LoyaltyService');
    } catch (e) {
      AppLogger.error('Failed to credit welcome bonus: $e', tag: 'LoyaltyService');
    }
  }

  /// Redeem tokens at checkout (atomic transaction with balance check)
  Future<bool> redeemTokens({
    required String userId,
    required int tokensToRedeem,
    required String orderId,
  }) async {
    if (tokensToRedeem <= 0) return true;

    final accountDoc = _accountsRef.doc(userId);
    final txDoc = _transactionsRef.doc();

    try {
      final success = await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(accountDoc);
        if (!snapshot.exists) return false;

        final currentBalance = (snapshot.data()?['balance'] as num? ?? 0).toInt();
        if (currentBalance < tokensToRedeem) {
          throw Exception('Insufficient tokens balance ($currentBalance available, $tokensToRedeem requested)');
        }

        final newBalance = currentBalance - tokensToRedeem;
        final totalRedeemed = (snapshot.data()?['totalRedeemed'] as num? ?? 0).toInt() + tokensToRedeem;
        final now = DateTime.now();

        transaction.update(accountDoc, {
          'balance': newBalance,
          'totalRedeemed': totalRedeemed,
          'updatedAt': now.millisecondsSinceEpoch,
        });

        transaction.set(txDoc, {
          'userId': userId,
          'type': 'redeem',
          'amount': -tokensToRedeem,
          'balanceAfter': newBalance,
          'orderId': orderId,
          'description': 'Redeemed on Order #$orderId',
          'createdAt': now.millisecondsSinceEpoch,
        });

        return true;
      });

      return success;
    } catch (e) {
      AppLogger.error('Token redemption error: $e', tag: 'LoyaltyService');
      rethrow;
    }
  }

  /// Earn tokens for completed/delivered order
  Future<void> earnTokensForOrder({
    required String userId,
    required String orderId,
    required double orderAmount,
    int earnRate = 100, // 1 token per 100 Rs
  }) async {
    final tokensToEarn = (orderAmount / earnRate).floor();
    if (tokensToEarn <= 0) return;

    // Check idempotency: make sure orderId hasn't already earned tokens
    final existingTxs = await _transactionsRef
        .where('orderId', isEqualTo: orderId)
        .where('type', isEqualTo: 'earn')
        .limit(1)
        .get();

    if (existingTxs.docs.isNotEmpty) {
      AppLogger.info('Tokens already earned for order $orderId', tag: 'LoyaltyService');
      return;
    }

    final accountDoc = _accountsRef.doc(userId);
    final txDoc = _transactionsRef.doc();

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(accountDoc);
        final currentBalance = snapshot.exists ? (snapshot.data()?['balance'] as num? ?? 0).toInt() : 0;
        final currentEarned = snapshot.exists ? (snapshot.data()?['totalEarned'] as num? ?? 0).toInt() : 0;
        final newBalance = currentBalance + tokensToEarn;
        final now = DateTime.now();

        transaction.set(
          accountDoc,
          {
            'userId': userId,
            'balance': newBalance,
            'totalEarned': currentEarned + tokensToEarn,
            'updatedAt': now.millisecondsSinceEpoch,
          },
          SetOptions(merge: true),
        );

        transaction.set(txDoc, {
          'userId': userId,
          'type': 'earn',
          'amount': tokensToEarn,
          'balanceAfter': newBalance,
          'orderId': orderId,
          'description': 'Earned from Delivered Order #$orderId',
          'createdAt': now.millisecondsSinceEpoch,
        });
      });

      AppLogger.info('Earned $tokensToEarn tokens for order $orderId', tag: 'LoyaltyService');
    } catch (e) {
      AppLogger.error('Error earning tokens: $e', tag: 'LoyaltyService');
    }
  }

  /// Refund tokens if an order is cancelled
  Future<void> refundTokensForCancelledOrder({
    required String userId,
    required String orderId,
    required int tokensToRefund,
  }) async {
    if (tokensToRefund <= 0) return;

    final accountDoc = _accountsRef.doc(userId);
    final txDoc = _transactionsRef.doc();

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(accountDoc);
        final currentBalance = snapshot.exists ? (snapshot.data()?['balance'] as num? ?? 0).toInt() : 0;
        final currentRedeemed = snapshot.exists ? (snapshot.data()?['totalRedeemed'] as num? ?? 0).toInt() : 0;
        final newBalance = currentBalance + tokensToRefund;
        final newRedeemed = (currentRedeemed - tokensToRefund).clamp(0, double.infinity).toInt();
        final now = DateTime.now();

        transaction.update(accountDoc, {
          'balance': newBalance,
          'totalRedeemed': newRedeemed,
          'updatedAt': now.millisecondsSinceEpoch,
        });

        transaction.set(txDoc, {
          'userId': userId,
          'type': 'refund',
          'amount': tokensToRefund,
          'balanceAfter': newBalance,
          'orderId': orderId,
          'description': 'Refunded from Cancelled Order #$orderId',
          'createdAt': now.millisecondsSinceEpoch,
        });
      });

      AppLogger.info('Refunded $tokensToRefund tokens for order $orderId', tag: 'LoyaltyService');
    } catch (e) {
      AppLogger.error('Error refunding tokens: $e', tag: 'LoyaltyService');
    }
  }

  /// Super Admin stats for total issued vs redeemed
  Future<Map<String, int>> getGlobalLoyaltyStats() async {
    try {
      final snapshot = await _accountsRef.get();
      int totalBalance = 0;
      int totalEarned = 0;
      int totalRedeemed = 0;

      for (final doc in snapshot.docs) {
        final d = doc.data();
        totalBalance += (d['balance'] as num? ?? 0).toInt();
        totalEarned += (d['totalEarned'] as num? ?? 0).toInt();
        totalRedeemed += (d['totalRedeemed'] as num? ?? 0).toInt();
      }

      return {
        'totalBalance': totalBalance,
        'totalEarned': totalEarned,
        'totalRedeemed': totalRedeemed,
        'activeAccounts': snapshot.docs.length,
      };
    } catch (e) {
      AppLogger.error('Failed to get loyalty stats: $e', tag: 'LoyaltyService');
      return {
        'totalBalance': 0,
        'totalEarned': 0,
        'totalRedeemed': 0,
        'activeAccounts': 0,
      };
    }
  }
}
