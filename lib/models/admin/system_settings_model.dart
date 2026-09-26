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
  final bool isStoreOpen;
  final bool maintenanceMode;
  final bool allowCashOnDelivery;
  final bool allowOnlinePayment;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
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
    this.isStoreOpen = true,
    this.maintenanceMode = false,
    this.allowCashOnDelivery = true,
    this.allowOnlinePayment = true,
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
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
    bool? isStoreOpen,
    bool? maintenanceMode,
    bool? allowCashOnDelivery,
    bool? allowOnlinePayment,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
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
      isStoreOpen: isStoreOpen ?? this.isStoreOpen,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      allowCashOnDelivery: allowCashOnDelivery ?? this.allowCashOnDelivery,
      allowOnlinePayment: allowOnlinePayment ?? this.allowOnlinePayment,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
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
      'isStoreOpen': isStoreOpen,
      'maintenanceMode': maintenanceMode,
      'allowCashOnDelivery': allowCashOnDelivery,
      'allowOnlinePayment': allowOnlinePayment,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory SystemSettingsModel.fromJson(Map<String, dynamic> json) {
    return SystemSettingsModel(
      id: json['id'] ?? 'global_settings',
      appName: json['appName'] ?? 'Food Fight',
      restaurantName: json['restaurantName'] ?? 'Food Fight Restaurant HQ',
      contactEmail: json['contactEmail'] ?? 'contact@foodfight.pk',
      contactPhone: json['contactPhone'] ?? '+92 300 1234567',
      supportWhatsApp: json['supportWhatsApp'] ?? '+923001234567',
      defaultDeliveryCharge: (json['defaultDeliveryCharge'] ?? 150.0).toDouble(),
      freeDeliveryThreshold: (json['freeDeliveryThreshold'] ?? 2500.0).toDouble(),
      isStoreOpen: json['isStoreOpen'] ?? true,
      maintenanceMode: json['maintenanceMode'] ?? false,
      allowCashOnDelivery: json['allowCashOnDelivery'] ?? true,
      allowOnlinePayment: json['allowOnlinePayment'] ?? true,
      pushNotificationsEnabled: json['pushNotificationsEnabled'] ?? true,
      emailNotificationsEnabled: json['emailNotificationsEnabled'] ?? true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : DateTime.now(),
    );
  }

  factory SystemSettingsModel.fromMap(Map<String, dynamic> map) =>
      SystemSettingsModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}
