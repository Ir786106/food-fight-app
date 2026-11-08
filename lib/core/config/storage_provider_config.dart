import '../utils/logger.dart';

/// Storage provider enum
enum StorageProvider {
  firebase,
  supabase,
  cloudinary,
}

/// Central configuration for media and image storage across the platform.
/// Keeps image storage completely provider-agnostic.
class StorageProviderConfig {
  /// The active storage provider used for new uploads.
  /// Firebase Storage is primary for authenticated uploads and participant-scoped rules.
  static const StorageProvider activeProvider = StorageProvider.firebase;

  static const bool signedSupabaseUploads = bool.fromEnvironment('SIGNED_SUPABASE_UPLOADS');

  /// Whether Supabase should remain active as a read fallback for legacy URLs
  static const bool enableSupabaseReadFallback = true;

  /// Optional Cloudinary configuration if Firebase Blaze plan is not yet active
  static const String cloudinaryCloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: '');
  static const String cloudinaryUploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: '');

  /// Diagnostic logger to track image URL types
  static void logImageDiagnostic(String? rawUrl, {String? tag}) {
    final t = tag ?? 'ImageDiagnostic';
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      AppLogger.debug('Image is EMPTY or NULL', tag: t);
      return;
    }
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      if (trimmed.contains('supabase.co')) {
        AppLogger.debug('Image is FULL SUPABASE URL', tag: t);
      } else if (trimmed.contains('firebasestorage.googleapis.com')) {
        AppLogger.debug('Image is FULL FIREBASE STORAGE URL', tag: t);
      } else if (trimmed.contains('cloudinary.com')) {
        AppLogger.debug('Image is FULL CLOUDINARY URL', tag: t);
      } else {
        AppLogger.debug('Image is EXTERNAL HTTP URL', tag: t);
      }
    } else if (trimmed.startsWith('assets/')) {
      AppLogger.debug('Image is LOCAL ASSET: $trimmed', tag: t);
    } else {
      AppLogger.debug('Image is RELATIVE STORAGE PATH', tag: t);
    }
  }
}
