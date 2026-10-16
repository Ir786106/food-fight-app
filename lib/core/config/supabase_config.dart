import '../constants/app_constants.dart';

/// Configuration for Supabase image and media storage
class SupabaseConfig {
  /// Supabase Project URL (optional fallback)
  static const String url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  /// Supabase Publishable Key (injected via environment / dart-define, never committed)
  static const String publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: '');

  /// Legacy alias for publishableKey
  static const String anonKey = publishableKey;

  /// Storage bucket for food fight media assets
  static const String bucketName = AppConstants.supabaseImagesBucket;

  /// Storage folder categories (food-images/products, categories, banners, profiles, videos)
  static const String productsFolder = 'products/';
  static const String foodsFolder = 'products/'; // alias for products
  static const String categoriesFolder = 'categories/';
  static const String bannersFolder = 'banners/';
  static const String videosFolder = 'videos/';
  static const String profilesFolder = 'profiles/';

  /// Whether Supabase is configured with a valid URL and publishable key
  static bool get isConfigured =>
      url.isNotEmpty &&
      publishableKey.isNotEmpty &&
      !url.contains('your-project') &&
      !publishableKey.contains('your-key');
}
