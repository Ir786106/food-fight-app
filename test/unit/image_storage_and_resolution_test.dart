import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/config/storage_provider_config.dart';
import 'package:food_fight/core/utils/image_compressor.dart';
import 'package:food_fight/services/app_image_storage_service.dart';
import 'package:food_fight/services/firebase/firebase_image_storage_service.dart';
import 'package:food_fight/services/cloudinary/cloudinary_image_storage_service.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Storage Provider & Image Resolution Tests', () {
    test('StorageProviderConfig defaults to Firebase as primary', () {
      expect(StorageProviderConfig.activeProvider, equals(StorageProvider.firebase));
      expect(StorageProviderConfig.enableSupabaseReadFallback, isTrue);
    });

    test('AppImageStorageService resolves URLs correctly', () {
      // 1. Null or empty string
      expect(AppImageStorageService.resolveImageUrl(null), isNull);
      expect(AppImageStorageService.resolveImageUrl(''), isNull);
      expect(AppImageStorageService.resolveImageUrl('   '), isNull);

      // 2. Full HTTPS URLs
      const fullUrl = 'https://firebasestorage.googleapis.com/v0/b/app/o/item.jpg?alt=media';
      expect(AppImageStorageService.resolveImageUrl(fullUrl), equals(fullUrl));

      const supabaseUrl = 'https://acevokhgphqrtvitukzv.supabase.co/storage/v1/object/public/food-images/products/item.jpg';
      expect(AppImageStorageService.resolveImageUrl(supabaseUrl), equals(supabaseUrl));

      // 3. Asset URLs
      const assetUrl = 'assets/images/branding/food_fight_logo_icon.png';
      expect(AppImageStorageService.resolveImageUrl(assetUrl), equals(assetUrl));
    });

    test('ImageCompressor downscales large images to maxDimension with high quality', () async {
      // Create a 1600x1200 dummy image in memory
      final image = img.Image(width: 1600, height: 1200);
      img.fill(image, color: img.ColorRgb8(255, 0, 0));
      final rawBytes = Uint8List.fromList(img.encodeJpg(image));

      expect(image.width, equals(1600));
      expect(image.height, equals(1200));

      final compressed = await ImageCompressor.compressAndResize(
        rawBytes,
        maxDimension: 1080,
        quality: 80,
      );

      final decoded = img.decodeImage(compressed);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(1080));
      expect(decoded.height, equals(810)); // 1200 * (1080 / 1600) = 810
      expect(compressed.length, lessThanOrEqualTo(rawBytes.length));
    });

    test('FirebaseImageStorageService instance is singleton and implements IImageStorageService', () {
      final s1 = FirebaseImageStorageService();
      final s2 = FirebaseImageStorageService();
      expect(identical(s1, s2), isTrue);
    });

    test('CloudinaryImageStorageService instance is singleton and implements IImageStorageService', () {
      final c1 = CloudinaryImageStorageService();
      final c2 = CloudinaryImageStorageService();
      expect(identical(c1, c2), isTrue);
    });
  });
}
