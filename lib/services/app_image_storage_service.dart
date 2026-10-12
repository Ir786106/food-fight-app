import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:food_fight/core/config/storage_provider_config.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/services/interfaces/image_storage_service_interface.dart';
import 'package:food_fight/services/firebase/firebase_image_storage_service.dart';
import 'package:food_fight/services/supabase/supabase_image_storage_service.dart';
import 'package:food_fight/services/cloudinary/cloudinary_image_storage_service.dart';

/// Unified Application Image Storage Service.
/// Delegates uploads to the active provider (Firebase Storage by default).
/// Keeps Supabase as a read fallback for legacy URLs.
class AppImageStorageService implements IImageStorageService {
  static final AppImageStorageService _instance = AppImageStorageService._internal();
  AppImageStorageService._internal();
  factory AppImageStorageService() => _instance;

  static IImageStorageService get activeService {
    switch (StorageProviderConfig.activeProvider) {
      case StorageProvider.firebase:
        return FirebaseImageStorageService();
      case StorageProvider.cloudinary:
        return CloudinaryImageStorageService();
      case StorageProvider.supabase:
        return SupabaseImageStorageService();
    }
  }

  /// Pick an image safely with size limits
  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final ImagePicker picker = ImagePicker();
    try {
      return await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      AppLogger.error('Error picking image: $e', tag: 'AppImageStorage');
      return null;
    }
  }

  /// Resolves an image URL or storage path to an absolute, loadable HTTPS URL.
  /// Logs diagnostic information per image (empty, full URL, or relative path).
  static String? resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      StorageProviderConfig.logImageDiagnostic(null);
      return null;
    }

    final trimmed = rawUrl.trim();
    StorageProviderConfig.logImageDiagnostic(trimmed);

    // 1. Full HTTP/HTTPS URLs
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Uri.encodeFull(trimmed);
    }

    // 2. Local asset paths
    if (trimmed.startsWith('assets/')) {
      return trimmed;
    }

    // 3. Relative storage path
    final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;

    // First try active provider
    if (StorageProviderConfig.activeProvider == StorageProvider.firebase) {
      // If it's a relative path on Firebase, get public URL or resolve via Firebase storage
      final firebaseResolved = FirebaseImageStorageService().getImageUrl(cleanPath);
      if (firebaseResolved.startsWith('http')) {
        return Uri.encodeFull(firebaseResolved);
      }
    }

    // Fallback: Check if Supabase URL can resolve this relative path
    try {
      final supabaseUrl = SupabaseImageStorageService().getImageUrl(cleanPath);
      if (supabaseUrl.isNotEmpty && supabaseUrl.startsWith('http')) {
        return Uri.encodeFull(supabaseUrl);
      }
    } catch (e) {
      AppLogger.warn('Could not resolve relative path through Supabase: $e', tag: 'AppImageStorage');
    }

    return null;
  }

  @override
  Future<String> uploadImage({
    required XFile image,
    required String path,
    Function(double progress)? onProgress,
  }) {
    if (StorageProviderConfig.activeProvider == StorageProvider.firebase) {
      return FirebaseImageStorageService().uploadImage(image: image, path: path, onProgress: onProgress);
    } else if (StorageProviderConfig.activeProvider == StorageProvider.cloudinary) {
      return CloudinaryImageStorageService().uploadImage(image: image, path: path, onProgress: onProgress);
    }
    return SupabaseImageStorageService().uploadImage(image: image, path: path);
  }

  @override
  Future<String> uploadCompressedImage({
    required XFile image,
    required String path,
    int quality = 80,
    Function(double progress)? onProgress,
  }) {
    if (StorageProviderConfig.activeProvider == StorageProvider.firebase) {
      return FirebaseImageStorageService().uploadCompressedImage(
        image: image,
        path: path,
        quality: quality,
        onProgress: onProgress,
      );
    } else if (StorageProviderConfig.activeProvider == StorageProvider.cloudinary) {
      return CloudinaryImageStorageService().uploadCompressedImage(
        image: image,
        path: path,
        quality: quality,
        onProgress: onProgress,
      );
    }
    return SupabaseImageStorageService().uploadCompressedImage(image: image, path: path, quality: quality);
  }

  @override
  String getImageUrl(String path) => activeService.getImageUrl(path);

  @override
  Future<String> getPublicUrl(String path) => activeService.getPublicUrl(path);

  @override
  Future<Uint8List> downloadImage(String path) => activeService.downloadImage(path);

  @override
  Future<void> deleteImage(String path) => activeService.deleteImage(path);

  @override
  Future<bool> imageExists(String path) => activeService.imageExists(path);

  @override
  Future<String> updateImage({
    required XFile newImage,
    required String oldPath,
    required String newPath,
  }) => activeService.updateImage(newImage: newImage, oldPath: oldPath, newPath: newPath);

  @override
  Future<String> generateThumbnail({
    required XFile image,
    required String path,
    int width = 200,
    int height = 200,
  }) => activeService.generateThumbnail(image: image, path: path, width: width, height: height);
}
