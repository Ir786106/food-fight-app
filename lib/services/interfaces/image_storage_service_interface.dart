import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Interface for image storage service
abstract class IImageStorageService {
  /// Upload image to storage
  Future<String> uploadImage({
    required XFile image,
    required String path,
  });

  /// Upload image with compression
  Future<String> uploadCompressedImage({
    required XFile image,
    required String path,
    int quality = 85,
  });

  /// Get image URL from storage path
  String getImageUrl(String path);

  /// Get public URL for image
  Future<String> getPublicUrl(String path);

  /// Download image from storage
  Future<Uint8List> downloadImage(String path);

  /// Delete image from storage
  Future<void> deleteImage(String path);

  /// Check if image exists
  Future<bool> imageExists(String path);

  /// Update image
  Future<String> updateImage({
    required XFile newImage,
    required String oldPath,
    required String newPath,
  });

  /// Generate thumbnail
  Future<String> generateThumbnail({
    required XFile image,
    required String path,
    int width = 200,
    int height = 200,
  });
}
