import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'logger.dart';

/// Pure Dart image compressor and resizer.
/// Limits images to maximum dimension (default 1080px) and quality (~80%).
class ImageCompressor {
  /// Compresses and resizes raw image bytes.
  /// Guarantees width and height <= [maxDimension] and output quality <= [quality].
  static Future<Uint8List> compressAndResize(
    Uint8List inputBytes, {
    int maxDimension = 1080,
    int quality = 80,
  }) async {
    try {
      if (inputBytes.isEmpty) return inputBytes;

      final decoded = img.decodeImage(inputBytes);
      if (decoded == null) {
        AppLogger.warn('Could not decode image for compression, returning original bytes', tag: 'ImageCompressor');
        return inputBytes;
      }

      img.Image processed = decoded;
      final int origW = decoded.width;
      final int origH = decoded.height;

      // Downscale if larger than maxDimension
      if (origW > maxDimension || origH > maxDimension) {
        if (origW >= origH) {
          processed = img.copyResize(decoded, width: maxDimension);
        } else {
          processed = img.copyResize(decoded, height: maxDimension);
        }
      }

      final compressedJpg = img.encodeJpg(processed, quality: quality);
      AppLogger.info(
        'Compressed image from ${inputBytes.length} bytes (${origW}x$origH) to ${compressedJpg.length} bytes (${processed.width}x${processed.height})',
        tag: 'ImageCompressor',
      );
      return Uint8List.fromList(compressedJpg);
    } catch (e) {
      AppLogger.error('Image compression failed: $e, falling back to original', tag: 'ImageCompressor');
      return inputBytes;
    }
  }
}
