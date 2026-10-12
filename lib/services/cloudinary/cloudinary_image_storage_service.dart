import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_fight/core/config/storage_provider_config.dart';
import 'package:food_fight/core/utils/image_compressor.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/services/interfaces/image_storage_service_interface.dart';
import 'package:food_fight/core/errors/app_exception.dart';

/// Cloudinary Image Storage Service (Fallback provider if Firebase Blaze is not active).
class CloudinaryImageStorageService implements IImageStorageService {
  static final CloudinaryImageStorageService _instance = CloudinaryImageStorageService._internal();
  CloudinaryImageStorageService._internal();
  factory CloudinaryImageStorageService() => _instance;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ));

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

      final compressedBytes = await ImageCompressor.compressAndResize(
        rawBytes,
        maxDimension: 1080,
        quality: quality,
      );

      const cloudName = StorageProviderConfig.cloudinaryCloudName;
      const uploadPreset = StorageProviderConfig.cloudinaryUploadPreset;
      const uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          compressedBytes,
          filename: image.name.isNotEmpty ? image.name : 'upload.jpg',
        ),
        'upload_preset': uploadPreset,
        'folder': path.replaceAll('\\', '/'),
      });

      final response = await _dio.post(
        uploadUrl,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final secureUrl = response.data['secure_url']?.toString() ?? response.data['url']?.toString();
        if (secureUrl != null && secureUrl.isNotEmpty) {
          AppLogger.info('Cloudinary upload success: $secureUrl', tag: 'CloudinaryStorage');
          return secureUrl;
        }
      }

      throw StorageException(message: 'Upload failed with status ${response.statusCode}');
    } catch (e, stack) {
      AppLogger.error('Cloudinary upload error: $e\n$stack', tag: 'CloudinaryStorage');
      throw StorageException(
        message: 'No connection. Please check your internet and try again.',
      );
    }
  }

  @override
  String getImageUrl(String path) => path;

  @override
  Future<String> getPublicUrl(String path) async => path;

  @override
  Future<Uint8List> downloadImage(String path) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? []);
    } catch (e) {
      AppLogger.error('Cloudinary download error: $e', tag: 'CloudinaryStorage');
      return Uint8List(0);
    }
  }

  @override
  Future<void> deleteImage(String path) async {
    // Cloudinary client delete requires signature/admin API
    AppLogger.info('Cloudinary image deletion requested for $path', tag: 'CloudinaryStorage');
  }

  @override
  Future<bool> imageExists(String path) async {
    return path.isNotEmpty && path.startsWith('http');
  }

  @override
  Future<String> updateImage({
    required XFile newImage,
    required String oldPath,
    required String newPath,
  }) async {
    return uploadImage(image: newImage, path: newPath);
  }

  @override
  Future<String> generateThumbnail({
    required XFile image,
    required String path,
    int width = 200,
    int height = 200,
  }) async {
    return uploadCompressedImage(image: image, path: path, quality: 70);
  }
}
