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
    test('SupabaseConfig holds correct URL, publishable key and bucket name', () {
      expect(SupabaseConfig.url, 'https://acevokhgphqrtvitukzv.supabase.co');
      expect(SupabaseConfig.publishableKey, 'sb_publishable_IAGhxF2xmeKLKOR5ZqITcw_ksW0Ghdc');
      expect(SupabaseConfig.bucketName, 'food-images');
      expect(StoragePaths.bucketName, 'food-images');
      expect(SupabaseConfig.isConfigured, isTrue);

      // Verify no secret or service_role key is exposed
      expect(SupabaseConfig.publishableKey.toLowerCase().contains('service_role'), isFalse);
      expect(SupabaseConfig.publishableKey.toLowerCase().contains('secret'), isFalse);
    });

    test('Supabase can initialize without errors using publishable key', () async {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );

      final client = Supabase.instance.client;
      expect(client, isNotNull);

      // Verify storage bucket access can be targeted through client
      final storageBucket = client.storage.from(SupabaseConfig.bucketName);
      expect(storageBucket, isNotNull);
      final url = storageBucket.getPublicUrl('test.jpg');
      expect(url, contains(SupabaseConfig.url));
      expect(url, contains('food-images/test.jpg'));
    });

    test('SupabaseImageStorageService generates valid public URLs for food-images bucket', () {
      final storageService = SupabaseImageStorageService();
      final sampleUrl = storageService.getImageUrl('foods/sample_burger.jpg');
      
      expect(sampleUrl, contains('https://acevokhgphqrtvitukzv.supabase.co'));
      expect(sampleUrl, contains('/storage/v1/object/public/food-images/foods/sample_burger.jpg'));
    });

    test('Supabase live upload test against food-images bucket', () async {
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
      expect(imageUrl, contains('https://acevokhgphqrtvitukzv.supabase.co'));
      expect(imageUrl, contains('food-images/products/product_'));
    });
  });
}
