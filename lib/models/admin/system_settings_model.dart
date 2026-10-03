import '../../core/utils/safe_convert.dart';

/// System Settings Model for platform-wide configurations
class SystemSettingsModel {
  final String id;
  final String appName;
  final String restaurantName;
  final String contactEmail;
  final String contactPhone;
  final String supportWhatsApp;
  final double defaultDeliveryCharge;
  final double freeDeliveryThreshold;
  final int orderCancellationWindowMinutes;
  final bool isStoreOpen;
  final bool maintenanceMode;
  final bool allowCashOnDelivery;
  final bool allowOnlinePayment;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool smsNotificationsEnabled;
  final int welcomeTokens;
  final int loyaltyEarnRate; // Spend amount per token earned (e.g. 100 Rs)
  final double loyaltyRedeemRate; // Currency value per token redeemed (e.g. 1.0 Rs)
  final int minTokensToRedeem;
  final DateTime updatedAt;

  SystemSettingsModel({
    this.id = 'global_settings',
    this.appName = 'Food Fight',
    this.restaurantName = 'Food Fight Restaurant HQ',
    this.contactEmail = 'contact@foodfight.pk',
    this.contactPhone = '+92 300 1234567',
    this.supportWhatsApp = '+923001234567',
    this.defaultDeliveryCharge = 150.0,
    this.freeDeliveryThreshold = 2500.0,
    this.orderCancellationWindowMinutes = 10,
    this.isStoreOpen = true,
    this.maintenanceMode = false,
    this.allowCashOnDelivery = true,
    this.allowOnlinePayment = true,
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.smsNotificationsEnabled = true,
    this.welcomeTokens = 50,
    this.loyaltyEarnRate = 100,
    this.loyaltyRedeemRate = 1.0,
    this.minTokensToRedeem = 10,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  SystemSettingsModel copyWith({
    String? id,
    String? appName,
    String? restaurantName,
    String? contactEmail,
    String? contactPhone,
    String? supportWhatsApp,
    double? defaultDeliveryCharge,
    double? freeDeliveryThreshold,
    int? orderCancellationWindowMinutes,
    bool? isStoreOpen,
    bool? maintenanceMode,
    bool? allowCashOnDelivery,
    bool? allowOnlinePayment,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? smsNotificationsEnabled,
    int? welcomeTokens,
    int? loyaltyEarnRate,
    double? loyaltyRedeemRate,
    int? minTokensToRedeem,
    DateTime? updatedAt,
  }) {
    return SystemSettingsModel(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      restaurantName: restaurantName ?? this.restaurantName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      supportWhatsApp: supportWhatsApp ?? this.supportWhatsApp,
      defaultDeliveryCharge: defaultDeliveryCharge ?? this.defaultDeliveryCharge,
      freeDeliveryThreshold: freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      orderCancellationWindowMinutes:
          orderCancellationWindowMinutes ?? this.orderCancellationWindowMinutes,
      isStoreOpen: isStoreOpen ?? this.isStoreOpen,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      allowCashOnDelivery: allowCashOnDelivery ?? this.allowCashOnDelivery,
      allowOnlinePayment: allowOnlinePayment ?? this.allowOnlinePayment,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      smsNotificationsEnabled: smsNotificationsEnabled ?? this.smsNotificationsEnabled,
      welcomeTokens: welcomeTokens ?? this.welcomeTokens,
      loyaltyEarnRate: loyaltyEarnRate ?? this.loyaltyEarnRate,
      loyaltyRedeemRate: loyaltyRedeemRate ?? this.loyaltyRedeemRate,
      minTokensToRedeem: minTokensToRedeem ?? this.minTokensToRedeem,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appName': appName,
      'restaurantName': restaurantName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'supportWhatsApp': supportWhatsApp,
      'defaultDeliveryCharge': defaultDeliveryCharge,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'orderCancellationWindowMinutes': orderCancellationWindowMinutes,
      'isStoreOpen': isStoreOpen,
      'maintenanceMode': maintenanceMode,
      'allowCashOnDelivery': allowCashOnDelivery,
      'allowOnlinePayment': allowOnlinePayment,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'smsNotificationsEnabled': smsNotificationsEnabled,
      'welcomeTokens': welcomeTokens,
      'loyaltyEarnRate': loyaltyEarnRate,
      'loyaltyRedeemRate': loyaltyRedeemRate,
      'minTokensToRedeem': minTokensToRedeem,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory SystemSettingsModel.fromJson(Map<String, dynamic> json) {
    return SystemSettingsModel(
      id: json['id']?.toString() ?? 'global_settings',
      appName: json['appName']?.toString() ?? 'Food Fight',
      restaurantName: json['restaurantName']?.toString() ?? 'Food Fight Restaurant HQ',
      contactEmail: json['contactEmail']?.toString() ?? 'contact@foodfight.pk',
      contactPhone: json['contactPhone']?.toString() ?? '+92 300 1234567',
      supportWhatsApp: json['supportWhatsApp']?.toString() ?? '+923001234567',
      defaultDeliveryCharge: SafeConvert.toDouble(json['defaultDeliveryCharge'], 150.0),
      freeDeliveryThreshold: SafeConvert.toDouble(json['freeDeliveryThreshold'], 2500.0),
      orderCancellationWindowMinutes:
          SafeConvert.toInt(json['orderCancellationWindowMinutes'], 10),
      isStoreOpen: json['isStoreOpen'] ?? true,
      maintenanceMode: json['maintenanceMode'] ?? false,
      allowCashOnDelivery: json['allowCashOnDelivery'] ?? true,
      allowOnlinePayment: json['allowOnlinePayment'] ?? true,
      pushNotificationsEnabled: json['pushNotificationsEnabled'] ?? true,
      emailNotificationsEnabled: json['emailNotificationsEnabled'] ?? true,
      smsNotificationsEnabled: json['smsNotificationsEnabled'] ?? true,
      welcomeTokens: SafeConvert.toInt(json['welcomeTokens'], 50),
      loyaltyEarnRate: SafeConvert.toInt(json['loyaltyEarnRate'], 100),
      loyaltyRedeemRate: SafeConvert.toDouble(json['loyaltyRedeemRate'], 1.0),
      minTokensToRedeem: SafeConvert.toInt(json['minTokensToRedeem'], 10),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
    );
  }

  factory SystemSettingsModel.fromMap(Map<String, dynamic> map) =>
      SystemSettingsModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}
