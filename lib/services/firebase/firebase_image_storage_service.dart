import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_fight/core/utils/image_compressor.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/services/interfaces/image_storage_service_interface.dart';
import 'package:food_fight/core/errors/app_exception.dart';

/// Firebase Storage implementation of IImageStorageService.
/// Accessible in Pakistan without ISP/DNS domain blocking.
class FirebaseImageStorageService implements IImageStorageService {
  static final FirebaseImageStorageService _instance = FirebaseImageStorageService._internal();
  FirebaseImageStorageService._internal();
  factory FirebaseImageStorageService() => _instance;

  FirebaseStorage get _storage => FirebaseStorage.instance;

  static const List<String> supportedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

  /// Resolve MIME content-type based on file extension
  static String getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Format clean destination path
  String _normalizePath(String path) {
    var clean = path.trim().replaceAll('\\', '/');
    if (clean.startsWith('/')) clean = clean.substring(1);
    return clean;
  }

  /// Generate a unique filename: prefix_timestamp.jpg
  String _generateFileName(String path, String originalName) {
    final rawExt = originalName.split('.').last.toLowerCase();
    final cleanExt = supportedExtensions.contains(rawExt) ? rawExt : 'jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    String prefix = 'item';
    final lower = path.toLowerCase();
    if (lower.contains('product') || lower.contains('menu')) {
      prefix = 'product';
    } else if (lower.contains('categor')) {
      prefix = 'category';
    } else if (lower.contains('profile')) {
      prefix = 'profile';
    } else if (lower.contains('banner')) {
      prefix = 'banner';
    } else if (lower.contains('offer')) {
      prefix = 'offer';
    } else if (lower.contains('rider')) {
      prefix = 'rider';
    } else if (lower.contains('review')) {
      prefix = 'review';
    }

    return '${prefix}_$timestamp.$cleanExt';
  }

  @override
  Future<String> uploadImage({
    required XFile image,
    required String path,
    Function(double progress)? onProgress,
  }) async {
    return uploadCompressedImage(
      image: image,
      path: path,
      quality: 80,
      onProgress: onProgress,
    );
  }

  @override
  Future<String> uploadCompressedImage({
    required XFile image,
    required String path,
    int quality = 80,
    Function(double progress)? onProgress,
  }) async {
    try {
      final rawBytes = await image.readAsBytes();
      if (rawBytes.isEmpty) {
        throw StorageException(message: 'Image file is empty');
      }

      // Auto-compress and limit to max 1080px
      final compressedBytes = await ImageCompressor.compressAndResize(
        rawBytes,
        maxDimension: 1080,
        quality: quality,
      );

      final normalizedFolder = _normalizePath(path);
      final fileName = _generateFileName(normalizedFolder, image.name);
      final fullPath = normalizedFolder.endsWith('/')
          ? '$normalizedFolder$fileName'
          : '$normalizedFolder/$fileName';

      final ref = _storage.ref().child(fullPath);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'originalName': image.name,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putData(compressedBytes, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      AppLogger.info('Uploaded image successfully to Firebase Storage: $fullPath', tag: 'FirebaseStorage');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('Firebase Storage upload failed: $e\n$stackTrace', tag: 'FirebaseStorage');
      // Friendly, non-technical error message for UI
      throw StorageException(
        message: 'No connection. Please check your internet and try again.',
      );
    }
  }

  @override
  String getImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final clean = _normalizePath(path);
    try {
      return _storage.ref().child(clean).fullPath;
    } catch (_) {
      return path;
    }
  }

  @override
  Future<String> getPublicUrl(String path) async {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final clean = _normalizePath(path);
    try {
      final ref = _storage.ref().child(clean);
      return await ref.getDownloadURL();
    } catch (e) {
      AppLogger.warn('Could not get download URL for Firebase path "$path": $e', tag: 'FirebaseStorage');
      return path;
    }
  }

  @override
  Future<Uint8List> downloadImage(String path) async {
    try {
      final clean = _normalizePath(path);
      final ref = _storage.ref().child(clean);
      final data = await ref.getData(10 * 1024 * 1024); // max 10MB
      return data ?? Uint8List(0);
    } catch (e) {
      AppLogger.error('Failed to download image from Firebase: $e', tag: 'FirebaseStorage');
      return Uint8List(0);
    }
  }

  @override
  Future<void> deleteImage(String path) async {
    try {
      if (path.isEmpty) return;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        try {
          final ref = _storage.refFromURL(path);
          await ref.delete();
          AppLogger.info('Deleted image from Firebase: $path', tag: 'FirebaseStorage');
        } catch (e) {
          AppLogger.warn('Could not delete by URL: $e', tag: 'FirebaseStorage');
        }
      } else {
        final clean = _normalizePath(path);
        await _storage.ref().child(clean).delete();
        AppLogger.info('Deleted image from Firebase: $clean', tag: 'FirebaseStorage');
      }
    } catch (e) {
      AppLogger.warn('Delete failed in Firebase Storage: $e', tag: 'FirebaseStorage');
    }
  }

  @override
  Future<bool> imageExists(String path) async {
    try {
      final clean = _normalizePath(path);
      final ref = _storage.ref().child(clean);
      await ref.getMetadata();
      return true;
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
    final newUrl = await uploadImage(image: newImage, path: newPath);
    if (oldPath.isNotEmpty) {
      await deleteImage(oldPath);
    }
    return newUrl;
  }

  @override
  Future<String> generateThumbnail({
    required XFile image,
    required String path,
    int width = 200,
    int height = 200,
  }) async {
    final rawBytes = await image.readAsBytes();
    final thumbBytes = await ImageCompressor.compressAndResize(
      rawBytes,
      maxDimension: width > height ? width : height,
      quality: 75,
    );
    final normalized = _normalizePath(path);
    final fileName = 'thumb_${_generateFileName(normalized, image.name)}';
    final fullPath = normalized.endsWith('/') ? '$normalized$fileName' : '$normalized/$fileName';

    final ref = _storage.ref().child(fullPath);
    final snapshot = await ref.putData(thumbBytes, SettableMetadata(contentType: 'image/jpeg'));
    return await snapshot.ref.getDownloadURL();
  }
}
