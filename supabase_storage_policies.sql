-- ==============================================================================
-- Food Fight: Supabase Storage Bucket Security Policies
-- Bucket: 'food-images'
--
-- PURPOSE:
-- Supabase Storage is used EXCLUSIVELY for media files (food item images,
-- category icons, promotional banners, user avatars, videos).
--
-- ARCHITECTURE:
-- Authentication is handled by Firebase Authentication.
-- Flutter client connects to Supabase Storage using the anon/publishable key.
-- Authorization (admin checks) is enforced in Flutter via Firebase Auth.
-- The Storage policies below allow:
-- 1. SELECT (public read): Anyone can view food/menu photos.
-- 2. INSERT: App uploads new media to 'food-images' (products/, categories/, banners/, profiles/, videos/).
-- 3. UPDATE: App can update existing media in 'food-images'.
-- 4. DELETE: App can clean up old media in 'food-images'.
-- ==============================================================================

-- 1. Ensure the 'food-images' bucket exists, is public, and accepts all required media types
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'food-images',
  'food-images',
  true,
  52428800, -- 50 MB limit
  ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'image/svg+xml',
    'video/mp4',
    'video/webm',
    'video/quicktime',
    'video/x-msvideo'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  allowed_mime_types = ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'image/svg+xml',
    'video/mp4',
    'video/webm',
    'video/quicktime',
    'video/x-msvideo'
  ];

-- 2. Drop all previous / conflicting policies on storage.objects for 'food-images'
DROP POLICY IF EXISTS "Public Read Access for Food Images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Users Can Upload Food Images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Users Can Update Food Images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Users Can Delete Food Images" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow Uploads to food-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow Reads from food-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow Updates to food-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow Deletes from food-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow all access to food-images" ON storage.objects;
DROP POLICY IF EXISTS "food_images_select_policy" ON storage.objects;
DROP POLICY IF EXISTS "food_images_insert_policy" ON storage.objects;
DROP POLICY IF EXISTS "food_images_update_policy" ON storage.objects;
DROP POLICY IF EXISTS "food_images_delete_policy" ON storage.objects;

-- 4. Policy: SELECT (Read access for everyone)
CREATE POLICY "food_images_select_policy"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'food-images');

-- 5. Policy: INSERT (Upload access for bucket 'food-images')
-- Compatible with Firebase-authenticated client connecting via anon / publishable key
CREATE POLICY "food_images_insert_policy"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'food-images');

-- 6. Policy: UPDATE (Update access for bucket 'food-images')
CREATE POLICY "food_images_update_policy"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'food-images')
WITH CHECK (bucket_id = 'food-images');

-- 7. Policy: DELETE (Delete access for bucket 'food-images')
CREATE POLICY "food_images_delete_policy"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'food-images');
