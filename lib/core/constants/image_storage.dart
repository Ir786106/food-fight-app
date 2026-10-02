import 'package:food_fight/core/config/supabase_config.dart';

/// Supabase storage bucket configuration
class StoragePaths {
  // Bucket name (configured in Supabase dashboard)
  static const String bucketName = SupabaseConfig.bucketName;

  // Path prefixes for different media types
  static const String menuImagesPath = 'products/';
  static const String productImagesPath = 'products/';
  static const String categoryImagesPath = 'categories/';
  static const String userImagesPath = 'profiles/';
  static const String riderImagesPath = 'riders/';
  static const String bannerImagesPath = 'banners/';
  static const String offerImagesPath = 'offers/';
  static const String reviewImagesPath = 'reviews/';
  static const String videosPath = 'videos/';

  // Combined paths
  static String getMenuPath(String filename) =>
      '$menuImagesPath$filename';
  static String getCategoryPath(String filename) =>
      '$categoryImagesPath$filename';
  static String getUserPath(String filename) =>
      '$userImagesPath$filename';
  static String getRiderPath(String filename) =>
      '$riderImagesPath$filename';
  static String getBannerPath(String filename) =>
      '$bannerImagesPath$filename';
  static String getOfferPath(String filename) =>
      '$offerImagesPath$filename';
  static String getReviewPath(String filename) =>
      '$reviewImagesPath$filename';
  static String getVideoPath(String filename) =>
      '$videosPath$filename';
}
