import '../constants/app_constants.dart';

/// Configuration for Supabase image and media storage
class SupabaseConfig {
  /// Supabase Project URL
  static const String url = 'https://acevokhgphqrtvitukzv.supabase.co';

  /// Supabase Publishable Key (safe for client apps, NEVER use service_role)
  static const String publishableKey = 'sb_publishable_IAGhxF2xmeKLKOR5ZqITcw_ksW0Ghdc';

  /// Legacy alias for publishableKey
  static const String anonKey = publishableKey;

  /// Existing Supabase Storage bucket for food fight media assets
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
