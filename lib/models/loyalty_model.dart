import '../core/utils/safe_convert.dart';

/// Loyalty Account summary for a customer
class LoyaltyAccount {
  final String userId;
  final int balance;
  final int totalEarned;
  final int totalRedeemed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LoyaltyAccount({
    required this.userId,
    this.balance = 0,
    this.totalEarned = 0,
    this.totalRedeemed = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'balance': balance,
        'totalEarned': totalEarned,
        'totalRedeemed': totalRedeemed,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) {
    return LoyaltyAccount(
      userId: json['userId']?.toString() ?? '',
      balance: SafeConvert.toInt(json['balance']),
      totalEarned: SafeConvert.toInt(json['totalEarned']),
      totalRedeemed: SafeConvert.toInt(json['totalRedeemed']),
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
    );
  }

  LoyaltyAccount copyWith({
    String? userId,
    int? balance,
    int? totalEarned,
    int? totalRedeemed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoyaltyAccount(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalRedeemed: totalRedeemed ?? this.totalRedeemed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Loyalty Transaction record
class LoyaltyTransaction {
  final String id;
  final String userId;
  final String type; // 'bonus', 'earn', 'redeem', 'refund'
  final int amount; // positive or negative
  final int balanceAfter;
  final String? orderId;
  final String description;
  final DateTime createdAt;

  const LoyaltyTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.orderId,
    required this.description,
    required this.createdAt,
  });

  bool get isCredit => amount > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type,
        'amount': amount,
        'balanceAfter': balanceAfter,
        'orderId': orderId,
        'description': description,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'earn',
      amount: SafeConvert.toInt(json['amount']),
      balanceAfter: SafeConvert.toInt(json['balanceAfter']),
      orderId: json['orderId']?.toString(),
      description: json['description']?.toString() ?? '',
      createdAt: SafeConvert.toDateTime(json['createdAt']),
    );
  }
}
