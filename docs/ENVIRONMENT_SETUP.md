# Environment setup

Work inside food_fight. Install the Flutter SDK, Node version matching functions/package.json, Firebase CLI and Java for the emulator. Install Flutter packages with flutter pub get and Functions dependencies with npm ci in functions. Use .env.example for client configuration names and server-managed secrets for privileged credentials.

For staging, configure Firebase project registrations, phone Auth and app fingerprints, App Check, FCM and APNs, restricted Maps keys and Supabase storage settings. Use a demo project ID for emulator tests. For target verification use flutter build web and flutter build apk when their SDKs and configuration are available.

## Customer phone sign-in

The login screen supports Pakistani mobile numbers on Android, iOS and web. Firebase verifies the SMS code. completePhoneProfile checks the verified phone sign-in session and creates a customer profile only when a phone-only account has no profile. Existing profiles are preserved. Inactive accounts and staff profiles cannot sign in through the customer phone flow.

Enable the Phone provider and Pakistan SMS delivery in the separate staging project. Configure Android signing fingerprints, iOS APNs and remote notifications, and the web authorized domain. Use a Firebase test number first, then verify real SMS and reCAPTCHA or native app verification on the intended platforms. See https://firebase.google.com/docs/auth/flutter/phone-auth.

## Signed public image uploads

Set SUPABASE_URL for the Firebase Functions environment and bind the SUPABASE_SERVICE_ROLE_KEY secret to createSignedImageUpload. Use the same staging Supabase URL in the Flutter build, with SUPABASE_PUBLISHABLE_KEY and SIGNED_SUPABASE_UPLOADS=true as Dart defines. The service-role key stays on the server.

Configure the staging food-images bucket for public object reads, a 2 MiB upload limit and image/jpeg uploads. Review its storage policies and remove anonymous or client-role insert, update and delete access to the bucket before enabling the feature. The signed URL authorizes a single generated object path with overwrites disabled. Supabase controls token lifetime. Bucket limits are required because the callable only sees the client's declared size before issuing the token.

Verify signed upload, public read, unsigned write denial, size enforcement, and an unauthorized menu upload on staging. Profiles and catalog images are public. Chat attachments continue through Firebase participant rules. The rollout does not include private rider documents, server-side byte inspection, or cleanup of orphaned Supabase objects.
