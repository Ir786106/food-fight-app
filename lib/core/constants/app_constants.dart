/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Food Fight';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Hungry? Let\'s battle it out.';
  static const String logoPath = 'assets/images/branding/food_fight_logo_icon.png';
  static const String logoIconPath = 'assets/images/branding/food_fight_logo_icon.png';

  // API Settings
  static const int apiTimeoutSeconds = 30;
  static const int connectionTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;

  // Cache Settings
  static const int cacheDurationMinutes = 30;
  static const int maxCacheSizeMb = 100;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Image Settings
  static const int maxImageSizeKb = 2048; // 2MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const int imageCompressionQuality = 85;
  static const String supabaseImagesBucket = 'food-images';

  // Date/Time Formats
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayTimeFormat = 'hh:mm a';

  // Storage Keys (SharedPreferences)
  static const String storageThemeMode = 'ff_theme_mode';
  static const String storageCurrentUser = 'ff_current_user';
  static const String storageFirebaseToken = 'ff_firebase_token';
  static const String storageOnboardingCompleted = 'ff_onboarding_completed';

  // Firebase Collections
  static const String collectionUsers = 'users';
  static const String collectionCategories = 'categories';
  static const String collectionMenuItems = 'menuItems';
  static const String collectionOrders = 'orders';
  static const String collectionDeliveryAreas = 'deliveryAreas';
  static const String collectionRiders = 'riders';
  static const String collectionCoupons = 'coupons';
  static const String collectionReviews = 'reviews';
  static const String collectionNotifications = 'notifications';
  static const String collectionFavorites = 'favorites';
  static const String collectionAddresses = 'addresses';
  static const String collectionAuditLogs = 'auditLogs';
  static const String collectionSettings = 'settings';
  static const String collectionAudit = 'auditLogs';
}
