import '../core/utils/safe_convert.dart';

/// Saved payment method metadata. Card credentials are never stored.
class PaymentMethodModel {
  final String id;
  final String userId;
  final String type; // 'card', 'jazzcash', 'easypaisa'
  final String gateway; // 'stripe', 'jazzcash', 'easypaisa'
  final String maskedNumber; // e.g. '•••• 4242' or '0300 •••• 567'
  final String title;
  final String
      token; // Optional gateway token; empty when no gateway is integrated
  final String? accountReference;
  final String? cardBrand; // 'visa', 'mastercard', 'unionpay'
  final String? expiry;
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.gateway,
    required this.maskedNumber,
    required this.title,
    required this.token,
    this.accountReference,
    this.cardBrand,
    this.expiry,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'gateway': gateway,
      'maskedNumber': maskedNumber,
      'title': title,
      'token': token,
      if (accountReference != null) 'accountReference': accountReference,
      'cardBrand': cardBrand,
      'expiry': expiry,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'card',
      gateway: json['gateway']?.toString() ?? 'stripe',
      maskedNumber: json['maskedNumber']?.toString() ?? '•••• ••••',
      title: json['title']?.toString() ?? 'Payment Method',
      token: json['token']?.toString() ?? '',
      accountReference: json['accountReference']?.toString(),
      cardBrand: json['cardBrand']?.toString(),
      expiry: json['expiry']?.toString(),
      isDefault: json['isDefault'] == 1 || json['isDefault'] == true,
      createdAt: SafeConvert.toDateTime(json['createdAt']),
    );
  }
}
