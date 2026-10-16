import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_fight/core/config/supabase_config.dart';
import 'package:food_fight/core/constants/image_storage.dart';
import 'package:food_fight/services/supabase/supabase_image_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Configuration & Integration Tests', () {
    setUp(() {
      HttpOverrides.global = null;
      SharedPreferences.setMockInitialValues({});
    });
    test('SupabaseConfig securely defaults without committed credentials', () {
      expect(SupabaseConfig.bucketName, 'food-images');
      expect(StoragePaths.bucketName, 'food-images');
      // Verify no secret or service_role key is exposed
      expect(SupabaseConfig.publishableKey.toLowerCase().contains('service_role'), isFalse);
      expect(SupabaseConfig.publishableKey.toLowerCase().contains('secret'), isFalse);
    });

    test('Supabase can initialize when credentials are provided', () async {
      if (!SupabaseConfig.isConfigured) {
        expect(SupabaseConfig.isConfigured, isFalse);
        return;
      }
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );

      final client = Supabase.instance.client;
      expect(client, isNotNull);

      final storageBucket = client.storage.from(SupabaseConfig.bucketName);
      expect(storageBucket, isNotNull);
      final url = storageBucket.getPublicUrl('test.jpg');
      expect(url, contains(SupabaseConfig.url));
      expect(url, contains('food-images/test.jpg'));
    });

    test('SupabaseImageStorageService generates consistent paths for food-images bucket', () {
      final storageService = SupabaseImageStorageService();
      if (!SupabaseConfig.isConfigured) {
        expect(storageService.getImageUrl('foods/sample_burger.jpg'), isEmpty);
      } else {
        final sampleUrl = storageService.getImageUrl('foods/sample_burger.jpg');
        expect(sampleUrl, contains('foods/sample_burger.jpg'));
      }
    });

    test('Supabase live upload test against food-images bucket', () async {
      if (!SupabaseConfig.isConfigured) {
        return;
      }
      try {
        final client = Supabase.instance.client;
        final filePath = 'products/product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final testBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46]);

        final res = await client.storage.from('food-images').uploadBinary(
          filePath,
          testBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );
        expect(res, contains('food-images/products/product_'));

        final imageUrl = client.storage.from('food-images').getPublicUrl(filePath);
        expect(imageUrl, contains(SupabaseConfig.url));
        expect(imageUrl, contains('food-images/products/product_'));
      } catch (e) {
        // Live integration test graceful handling in offline environments
        expect(e.toString(), contains('SocketException'));
      }
    });
  });
}
