import '../core/utils/safe_convert.dart';

/// Secure tokenized payment method model.
/// NEVER stores raw card or account numbers.
class PaymentMethodModel {
  final String id;
  final String userId;
  final String type; // 'card', 'jazzcash', 'easypaisa'
  final String gateway; // 'stripe', 'jazzcash', 'easypaisa'
  final String maskedNumber; // e.g. '•••• 4242' or '0300 •••• 567'
  final String title;
  final String token; // Gateway reference token
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
      cardBrand: json['cardBrand']?.toString(),
      expiry: json['expiry']?.toString(),
      isDefault: json['isDefault'] == 1 || json['isDefault'] == true,
      createdAt: SafeConvert.toDateTime(json['createdAt']),
    );
  }
}
