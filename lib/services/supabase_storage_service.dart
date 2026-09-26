import 'supabase/supabase_image_storage_service.dart';
export 'supabase/supabase_image_storage_service.dart';

/// Centralized alias for SupabaseStorageService.
/// Encapsulates all media storage access (food images, category icons, banners, and videos)
/// for the food-images bucket.
typedef SupabaseStorageService = SupabaseImageStorageService;
