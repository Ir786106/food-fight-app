import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// Utility class for image handling
class ImageUtils {
  // Image size limits
  static const int maxImageSizeKB = 2048; // 2MB
  static const int maxWidth = 1920;
  static const int maxHeight = 1080;

  // Supported image types
  static const List<String> allowedTypes = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  // Get file extension
  static String? getExtension(String? filePath) {
    if (filePath == null) return null;
    return path.extension(filePath).toLowerCase().replaceFirst('.', '');
  }

  // Check if image type is allowed
  static bool isAllowedType(String? filePath) {
    final ext = getExtension(filePath);
    return ext != null && allowedTypes.contains(ext);
  }

  // Validate image size
  static Future<bool> isValidSize(XFile file) async {
    final bytes = await file.readAsBytes();
    return bytes.lengthInBytes <= maxImageSizeKB * 1024;
  }

  // Get file size in KB
  static Future<int> getSizeKB(XFile file) async {
    final bytes = await file.readAsBytes();
    return bytes.lengthInBytes ~/ 1024;
  }

  // Generate unique filename
  static String generateFilename(String prefix, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix$timestamp.$extension';
  }

  // Get filename without extension
  static String getFilenameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  // Get MIME type
  static String? getMimeType(String? filePath) {
    final ext = getExtension(filePath);
    if (ext == null) return null;

    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  // Validate image before upload
  static Future<ValidationResult> validateImage(XFile file) async {
    final ext = getExtension(file.path);
    if (ext == null || !allowedTypes.contains(ext)) {
      return ValidationResult(
        isValid: false,
        error: 'Invalid image format. Please use JPG, PNG, or WebP.',
      );
    }

    final sizeKB = await getSizeKB(file);
    if (sizeKB > maxImageSizeKB) {
      return ValidationResult(
        isValid: false,
        error: 'Image size exceeds ${maxImageSizeKB}KB limit.',
      );
    }

    return ValidationResult(isValid: true);
  }
}

/// Result of image validation
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({
    required this.isValid,
    this.error,
  });
}
