# Deployment sequence

Use a separate staging Firebase project with seeded test data. Verify Functions runtime compatibility, rules and indexes, then publish checkout callables to staging before testing a client that uses quoteOrder. Verify the staged Android and web targets with the real configured Auth, Maps, FCM, App Check and Supabase services.

Production deployment needs explicit authorization and a reviewed rollback and migration plan. Current local changes are a development checkpoint.

Deploy the order index and mutateOrder callable to staging before distributing clients that use the new order workflow. Apply server-only write rules when staging clients have migrated and verify that old clients are retired before any production rollout. Older clients used direct writes to advance orders and will need the new build.

## Staging verification

The configured default project is the production project. Obtain a separate staging project ID and register staging app credentials in an isolated staging checkout. Verify the generated Flutter configuration and Android Firebase registration both point to staging. Install dependencies, analyze the client, and use an explicit staging project ID for all Firebase commands. Verify the Firestore indexes have finished building before testing dispatch. Cloud Scheduler must be available for offer expiry.

Use test accounts for customer, branch manager and two riders. Seed a staging branch, delivery area and menu item. Enable autoDispatchEnabled on that branch. Place a COD order on the customer device, advance it through the kitchen, let the first rider offer expire, and accept on the second rider device. Complete pickup, delivery and cash collection. Confirm cash handover in the kitchen admin screen and check that duplicate confirmation preserves the same settlement. Verify no customer or other branch can perform the staff actions.

## Separate Flutter entry points

The shared Flutter project has three role-specific entry points. From food_fight, use:

    flutter run -t lib/main_customer.dart
    flutter run -t lib/main_rider.dart
    flutter run -t lib/main_admin.dart

For independent web build output directories, use:

    flutter build web -t lib/main_customer.dart --output build/editions/customer
    flutter build web -t lib/main_rider.dart --output build/editions/rider
    flutter build web -t lib/main_admin.dart --output build/editions/admin

The restricted builds verify the signed-in profile against Firestore before opening a session and expose only their edition's named routes. The admin build includes branch admin, staff, sub-admin and super admin. Server authorization still relies on the existing Firebase roles and Firestore rules.

Use separate staging web origins to test multiple roles concurrently because Firebase Auth can share a session between pages on the same origin. The mobile targets currently share the existing app identifiers and Firebase registration. Separate installable and store-distributed apps require independent identifiers, signing and staging Firebase app registrations. The combined app remains available through lib/main.dart.

## Local web demo before staging

From the Flutter project directory with Functions dependencies installed, start the demo emulators in a terminal:

    $env:FUNCTIONS_DISCOVERY_TIMEOUT = '60'
    firebase emulators:start --config firebase.demo.json --project demo-food-fight --only auth,functions,firestore,storage

In a second PowerShell terminal in the same directory, seed the emulator:

    $env:GCLOUD_PROJECT = 'demo-food-fight'
    $env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9187'
    $env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8687'
    node functions/seed_local_demo.js

Run each role in a separate terminal on a distinct browser origin:

    flutter run -d chrome --web-hostname 127.0.0.1 --web-port 8101 -t lib/main_customer.dart --dart-define=FOODFIGHT_LOCAL_DEMO=true
    flutter run -d chrome --web-hostname 127.0.0.1 --web-port 8102 -t lib/main_rider.dart --dart-define=FOODFIGHT_LOCAL_DEMO=true
    flutter run -d chrome --web-hostname 127.0.0.1 --web-port 8103 -t lib/main_admin.dart --dart-define=FOODFIGHT_LOCAL_DEMO=true

Use demo-customer@example.test, demo-rider@example.test and demo-admin@example.test respectively. The emulator-only password for each is FoodFight-Demo-123. The seed script creates missing data and preserves any orders and inventory already in the emulator. The demo is limited to debug web builds and displays the Firebase Auth emulator notice at the bottom of the browser. Password sign-in, Firestore, callables and Firebase Storage use loopback endpoints. Phone, Google sign-in, push registration, Supabase bootstrap and automatic update checks are outside this demo.

## Publish an Android update

1. Increase the version and Android build number in `pubspec.yaml`. Build the combined APK with the existing Food Fight release signing key using `flutter build apk --release --target-platform android-arm,android-arm64`.
2. Check the APK version and signing certificate with Android SDK Build Tools. Push the source commit to GitHub.
3. Publish a GitHub Release for that commit with a tag such as `v1.7.6` and a line such as `Build: 14` in the release description. Attach the signed APK and its matching `<filename>.apk.sha256` file, whose first field is the SHA-256 digest of the APK. Publish both files together.

Android checks the latest public release when Food Fight opens or resumes, subject to a six-hour throttle. Settings has a manual check and an opt-in automatic download switch. Food Fight verifies the checksum and Android handles the installation, including any required permission or confirmation.

For GitHub Actions to build and publish on a version tag, configure the repository variable `ENABLE_ANDROID_RELEASE=true` and the protected repository secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` and `GOOGLE_SERVICES_JSON`. Keep those files and values out of Git.
