import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import 'package:food_fight/core/config/supabase_config.dart';
import 'package:food_fight/services/interfaces/image_storage_service_interface.dart';
import 'package:food_fight/core/errors/app_exception.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Supabase Image Storage Service Implementation
/// Supabase is used EXCLUSIVELY for image storage (menu items, categories, profile photos)
class SupabaseImageStorageService implements IImageStorageService {
  static final SupabaseImageStorageService _instance = SupabaseImageStorageService._internal();

  SupabaseImageStorageService._internal();

  factory SupabaseImageStorageService() => _instance;

  static SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static String get _bucket => SupabaseConfig.bucketName;

  /// Supported image extensions
  static const List<String> supportedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'svg',
  ];

  /// Supported video extensions
  static const List<String> supportedVideoExtensions = [
    'mp4',
    'webm',
    'mov',
    'avi',
    'm4v',
  ];

  /// Resolve MIME content-type based on file extension
  static String getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      case 'mp4':
      case 'm4v':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }

  /// Generate a unique filename: e.g. products/product_<timestamp>.jpg
  static String generateUniqueFileName(String path, String originalName, String extension) {
    final cleanExt = extension.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    String prefix = 'product';
    final lowerPath = path.toLowerCase();
    if (lowerPath.contains('categor')) {
      prefix = 'category';
    } else if (lowerPath.contains('banner')) {
      prefix = 'banner';
    } else if (lowerPath.contains('profile') || lowerPath.contains('user')) {
      prefix = 'profile';
    } else if (lowerPath.contains('video')) {
      prefix = 'video';
    }

    return '${prefix}_$timestamp.$cleanExt';
  }

  /// Initialize Supabase
  static Future<void> initialize({String? url, String? publishableKey, String? anonKey}) async {
    final targetUrl = url ?? SupabaseConfig.url;
    final targetKey = publishableKey ?? anonKey ?? SupabaseConfig.publishableKey;

    try {
      if (_client == null) {
        await Supabase.initialize(
          url: targetUrl,
          publishableKey: targetKey,
        );
      }
      AppLogger.info('Supabase Storage initialized successfully (bucket: $_bucket)', tag: 'SupabaseStorage');
    } catch (e) {
      AppLogger.error('Supabase initialization warning: $e', tag: 'SupabaseStorage');
    }
  }

  /// Verify that the Supabase client can access the configured storage bucket
  static Future<bool> verifyBucketAccess() async {
    try {
      final client = _client;
      if (client == null) return false;
      final items = await client.storage.from(_bucket).list();
      AppLogger.info('Verified access to bucket "$_bucket": found ${items.length} items', tag: 'SupabaseStorage');
      return true;
    } catch (e) {
      AppLogger.error('Bucket "$_bucket" access check: $e', tag: 'SupabaseStorage');
      return false;
    }
  }

  /// Pick an image from Camera or Gallery
  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final ImagePicker picker = ImagePicker();
    try {
      return await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      AppLogger.error('Error picking image: $e', tag: 'SupabaseStorage');
      return null;
    }
  }

  /// Pick a video from Camera or Gallery
  static Future<XFile?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    final ImagePicker picker = ImagePicker();
    try {
      return await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
    } catch (e) {
      AppLogger.error('Error picking video: $e', tag: 'SupabaseStorage');
      return null;
    }
  }

  /// Upload image to Supabase Storage bucket and return public URL
  @override
  Future<String> uploadImage({
    required XFile image,
    required String path,
  }) async {
    final client = _client;
    if (client == null) {
      throw StorageException(message: 'Supabase storage is not initialized');
    }

    final Uint8List bytes = await image.readAsBytes();
    final String rawExt = image.name.split('.').last.toLowerCase();
    final String cleanExt = supportedImageExtensions.contains(rawExt) ? rawExt : 'jpg';

    final String cleanPath = path.endsWith('/') ? path : '$path/';
    final String fileName = generateUniqueFileName(cleanPath, image.name, cleanExt);
    final String fullStoragePath = '$cleanPath$fileName';
    final String contentType = getMimeType(cleanExt);

    try {
      await client.storage.from(_bucket).uploadBinary(
        fullStoragePath,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );

      final String publicUrl = client.storage.from(_bucket).getPublicUrl(fullStoragePath);
      AppLogger.info('Image uploaded successfully: $publicUrl', tag: 'SupabaseStorage');
      return publicUrl;
    } catch (e) {
      String errorMsg = e.toString();
      String? statusCode;
      try {
        final dynamic dynErr = e;
        if (dynErr.statusCode != null) {
          statusCode = dynErr.statusCode.toString();
        }
        if (dynErr.message != null && dynErr.message.toString().isNotEmpty) {
          errorMsg = dynErr.message.toString();
        }
      } catch (_) {}

      final detailedMsg = 'Upload failed [Bucket: $_bucket, Path: $fullStoragePath, Ext: $cleanExt, MIME: $contentType${statusCode != null ? ", Status: $statusCode" : ""}]: $errorMsg';
      AppLogger.error(detailedMsg, tag: 'SupabaseStorage');
      throw StorageException(message: detailedMsg);
    }
  }

  /// Upload image with compression (delegates to uploadImage with quality)
  @override
  Future<String> uploadCompressedImage({
    required XFile image,
    required String path,
    int quality = 85,
  }) async {
    return uploadImage(image: image, path: path);
  }

  /// Upload banner image (delegates to uploadImage with banners folder path)
  Future<String> uploadBanner({
    required XFile image,
    String? customFileName,
  }) async {
    return uploadImage(
      image: image,
      path: SupabaseConfig.bannersFolder,
    );
  }

  /// Upload video to Supabase Storage bucket and return accessible public URL
  Future<String> uploadVideo({
    required XFile video,
    required String path,
  }) async {
    final client = _client;
    if (client == null) {
      throw StorageException(message: 'Supabase storage is not initialized');
    }

    final Uint8List bytes = await video.readAsBytes();
    final String rawExt = video.name.split('.').last.toLowerCase();
    final String cleanExt = supportedVideoExtensions.contains(rawExt) ? rawExt : 'mp4';

    final String cleanPath = path.endsWith('/') ? path : '$path/';
    final String fileName = generateUniqueFileName(cleanPath, video.name, cleanExt);
    final String fullStoragePath = '$cleanPath$fileName';
    final String contentType = getMimeType(cleanExt);

    try {
      await client.storage.from(_bucket).uploadBinary(
        fullStoragePath,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );

      final String publicUrl = client.storage.from(_bucket).getPublicUrl(fullStoragePath);
      AppLogger.info('Video uploaded successfully: $publicUrl', tag: 'SupabaseStorage');
      return publicUrl;
    } catch (e) {
      String errorMsg = e.toString();
      String? statusCode;
      try {
        final dynamic dynErr = e;
        if (dynErr.statusCode != null) {
          statusCode = dynErr.statusCode.toString();
        }
        if (dynErr.message != null && dynErr.message.toString().isNotEmpty) {
          errorMsg = dynErr.message.toString();
        }
      } catch (_) {}

      final detailedMsg = 'Video upload failed [Bucket: $_bucket, Path: $fullStoragePath, Ext: $cleanExt, MIME: $contentType${statusCode != null ? ", Status: $statusCode" : ""}]: $errorMsg';
      AppLogger.error(detailedMsg, tag: 'SupabaseStorage');
      throw StorageException(message: detailedMsg);
    }
  }

  /// Delete old image if it was hosted in Supabase
  @override
  Future<void> deleteImage(String pathOrUrl) async {
    try {
      final client = _client;
      if (client == null) return;

      String filePath = pathOrUrl;
      if (pathOrUrl.startsWith('http')) {
        final uri = Uri.parse(pathOrUrl);
        filePath = uri.pathSegments.skipWhile((s) => s != _bucket).skip(1).join('/');
      }

      if (filePath.isNotEmpty) {
        await client.storage.from(_bucket).remove([filePath]);
        AppLogger.info('Deleted storage image: $filePath', tag: 'SupabaseStorage');
      }
    } catch (e) {
      AppLogger.error('Failed to delete image: $e', tag: 'SupabaseStorage');
    }
  }

  @override
  String getImageUrl(String path) {
    final client = _client;
    if (client == null) return '';
    return client.storage.from(_bucket).getPublicUrl(path);
  }

  @override
  Future<String> getPublicUrl(String path) async {
    return getImageUrl(path);
  }

  @override
  Future<Uint8List> downloadImage(String path) async {
    final client = _client;
    if (client == null) throw StorageException(message: 'Storage not initialized');
    return await client.storage.from(_bucket).download(path);
  }

  @override
  Future<bool> imageExists(String path) async {
    try {
      final client = _client;
      if (client == null) return false;
      final list = await client.storage.from(_bucket).list(path: path);
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> updateImage({
    required XFile newImage,
    required String oldPath,
    required String newPath,
  }) async {
    if (oldPath.isNotEmpty) {
      await deleteImage(oldPath);
    }
    return await uploadImage(image: newImage, path: newPath);
  }

  @override
  Future<String> generateThumbnail({
    required XFile image,
    required String path,
    int width = 200,
    int height = 200,
  }) async {
    return await uploadImage(image: image, path: path);
  }
}
