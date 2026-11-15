# Deployment sequence

Use a separate staging Firebase project with seeded test data. Verify runtime compatibility, rules and indexes, then make the configured checkout backend available before testing a client that uses quoteOrder. Verify the staged Android and web targets with the real configured Auth, Maps, FCM, App Check and Supabase services.

Production deployment needs explicit authorization and a reviewed rollback and migration plan. Current local changes are a development checkpoint.

## Trusted backend with Firebase on the free plan

The Node service in `functions/trusted_backend.js` runs the existing checkout, order lifecycle and Super Admin account handlers. Firebase Auth and Firestore stay in the same project. The service verifies Firebase ID tokens and current account permissions. Order cancellation and delivery reconciliation commit with the order transition, including inventory restoration and rider totals.

1. Run the integration checks against local demo Auth and Firestore.

       firebase emulators:exec --config firebase.demo.json --project demo-food-fight --only auth,firestore "node --test functions/order_lifecycle.emulator.test.js"

2. On a separate staging Firebase project, deploy the reviewed Firestore rules and indexes before connecting the HTTP service. The paired rules must restrict client writes to orders, assignments, protected account fields and private financial collections. Confirm the indexes are ready.
3. On the external Node host, use `functions` as the service root, `npm ci --omit=dev` as the build command, `node trusted_backend.js` as the start command and `/health` as the startup check. Set `GCLOUD_PROJECT` to the staging ID and provide Application Default Credentials through the host's secret manager, using a dedicated service identity authorized for Firestore and Firebase Auth account management. If the host uses a credential file, set `GOOGLE_APPLICATION_CREDENTIALS` to the mounted secret path. Set `FOODFIGHT_WEB_ORIGINS` to a comma-separated list of exact deployed web origins when serving Flutter Web. Keep credentials on the server.
4. Build the client with `--dart-define=FOODFIGHT_BACKEND_URL=https://YOUR-VERIFIED-HOST`. Run the checkout, rider, kitchen and Super Admin smoke tests with staging accounts. Verify a retried checkout returns the same order and cancellation restores stock once.
5. Review the cutover together before configuring production credentials or publishing production rules. Clients built without the URL continue using Firebase callables. Keep older clients in mind when coordinating the rules rollout.

This service handles request-driven operations. Use manual rider assignment for the initial rollout. Scheduled offer expiry, automatic dispatch triggers and background push notifications need separate workers. A free host may sleep between requests.

### Render staging setup

The root `render.yaml` defines a free Node web service with manual deploys. In Render, connect the GitHub review branch that contains the Blueprint. Set the prompted `GCLOUD_PROJECT` to the separate staging ID. In the service's Environment page, mount the staging service account JSON as a secret file named `firebase-service-account.json`, then trigger a manual deploy. Confirm that `/health` serves liveness and use a staging account for the authenticated checks above. The Blueprint's staging process refuses the production Firebase project ID.

### Render production configuration

For the authorized production target, select `render.production.yaml` as the Blueprint path in Render. It pins `food-fight-bd72e`, uses the Free instance plan and keeps deploys manual. Mount the dedicated production service account as the secret file `firebase-service-account.json`. Startup requires the credential's project to match. Keep the endpoint out of distributed clients until the deployed Firestore rules and client compatibility are reviewed together. Keep production rules publication on hold until the coordinated cutover is approved.

Deploy the order index and configure the staging order backend before distributing clients that use the new order workflow. Verify that old clients are retired before applying server-only write rules in production. Older clients used direct writes to advance orders and will need the new build.

## Staging verification

The configured default project is the production project. Obtain a separate staging project ID and register staging app credentials in an isolated staging checkout. Verify the generated Flutter configuration and Android Firebase registration both point to staging. Install dependencies, analyze the client, and use an explicit staging project ID for all Firebase commands. Verify the Firestore indexes have finished building before testing dispatch. Cloud Scheduler must be available for offer expiry.

Use test accounts for customer, branch manager and two riders. Seed a staging branch, delivery area and menu item. Enable autoDispatchEnabled on that branch. Place a COD order on the customer device, advance it through the kitchen, let the first rider offer expire, and accept on the second rider device. Complete pickup, delivery and cash collection. Confirm cash handover in the kitchen admin screen and check that duplicate confirmation preserves the same settlement. Verify no customer or other branch can perform the staff actions.

### Super Admin desktop smoke test

On the Firebase free plan, the dashboard reads aggregate counts from Firestore under the existing Super Admin rules. The Windows Firestore plugin supports counts only. The web app can show delivered GMV and the seven-day chart, using the checked-in orders index on `status` and `createdAt`. Admin account changes still require the authorized `mutatePlatform` callable.

Run the callable regression against the local emulators before staging.

    firebase emulators:exec --inspect-functions --config firebase.demo.json --project demo-food-fight --only auth,firestore,functions "node --test functions/platform_callable.emulator.test.js"

After the staging Functions deployment, confirm that `firebase functions:list --project STAGING_PROJECT_ID` shows `getPlatformMetrics` and `mutatePlatform` in `us-central1`. Use the staging Windows build and seeded accounts for these checks.

1. Open System Dashboard as Super Admin. Compare the visible totals with the seeded branch metrics.
2. Assign a staging Branch Admin to a staging branch and change one permission. Reopen the account and verify both changes persisted. Sign in as that Branch Admin and verify their permitted screens and branch.
3. Open Global Customer Chat. Verify that two seeded branches appear in the all-branches view. Select a conversation, type an unsent reply and switch branches. Verify that the previous conversation and reply are cleared. Check that Branch Admin can only see their assigned branch in Live Chat Support.
4. Open Platform Deals and Fleet & Riders. Verify the Super Admin sidebar stays visible. Open Branch Deals as Branch Admin and verify the list contains only that branch's deals.

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
    $env:FOOD_FIGHT_DEMO_PASSWORD = Read-Host -MaskInput 'Set an emulator-only password (12+ characters)'
    node functions/seed_local_demo.js

Run each role in a separate terminal on a distinct browser origin:

    flutter run -d chrome --web-hostname 127.0.0.1 --web-port 8101 -t lib/main_customer.dart --dart-define=FOODFIGHT_LOCAL_DEMO=true
    flutter run -d chrome --web-hostname 127.0.0.1 --web-port 8102 -t lib/main_rider.dart --dart-define=FOODFIGHT_LOCAL_DEMO=true
    flutter run -d chrome --web-hostname 127.0.0.1 --web-port 8103 -t lib/main_admin.dart --dart-define=FOODFIGHT_LOCAL_DEMO=true

Use demo-customer@example.test, demo-rider@example.test and demo-admin@example.test respectively. The emulator-only password for each is the value of FOOD_FIGHT_DEMO_PASSWORD. The seed script creates missing data and preserves any orders and inventory already in the emulator. The demo is limited to debug web builds and displays the Firebase Auth emulator notice at the bottom of the browser. Password sign-in, Firestore, callables and Firebase Storage use loopback endpoints. Phone, Google sign-in, push registration, Supabase bootstrap and automatic update checks are outside this demo.

## Backfill legacy tenant metadata

Run this against staging first. Every command takes an explicit project. Keep reports and export receipts outside the Git working tree because they contain internal document paths.

1. Use a project-specific private Cloud Storage bucket with Firestore export permissions. Run a full default-database export and save the operation name.

       gcloud firestore export gs://BACKUP_BUCKET/food-fight-before-tenant-backfill --project=PROJECT_ID --database="(default)" --async
       gcloud firestore operations describe OPERATION_NAME --project=PROJECT_ID --format=json > export-operation.json

   In PowerShell 7, you can use `| Set-Content -Encoding utf8NoBOM export-operation.json` in place of redirection. Confirm the operation reports `done: true`, no error and a Cloud Storage output prefix. [Firestore export and import documentation](https://docs.cloud.google.com/firestore/native/docs/manage-data/export-import)

2. Run the read-only audit and inspect unresolved ownership, status and roles.

       node functions/migrate_legacy_tenants.js --project=PROJECT_ID --report=tenant-dry-run.json --batch-size=100 --delay-ms=200

3. With the verified export receipt, apply the same scope in staging. If interrupted, repeat the command with `--resume` and the same report and receipt. A failed page leaves its checkpoint open. Resolve reported write conflicts before resuming. Avoid running concurrent instances with the same report.

       node functions/migrate_legacy_tenants.js --project=PROJECT_ID --report=tenant-apply.json --batch-size=100 --delay-ms=200 --backup-operation=export-operation.json --apply

4. Run a fresh dry run with a different report name. Confirm zero eligible changes, review all remaining issues, and check role access and checkout. Repeat with a separate production export and reports only after staging verification.

### Tenant backfill rollback

Keep the export and apply report. Stop migration workers and restore the export into a separate recovery database or project for comparison. Importing directly over live data can overwrite orders created after export.

    gcloud firestore import gs://BACKUP_BUCKET/ACTUAL_EXPORT_PREFIX --project=RECOVERY_PROJECT_ID --database="(default)"

To revert only the migration fields, use a reviewed recovery change built from the apply report and the exported original documents. Restore the original value for a field that existed as null or empty. Remove a field only if it was absent in the export, the apply report shows a committed migration, and the live value still matches the report's written value. Treat interrupted-page intents as candidates for comparison. Resolve later edits manually. The backfill performs no deletions.

## Move branch financials to private documents

Checkout and cancellation now write totals to `branchMetrics/{branchId}`. The Super Admin branch screens read that collection and can fall back to the legacy branch fields during rollout. Customer clients keep reading public branch metadata.

1. In staging, deploy the Functions, rules and updated staff client. Confirm that a new checkout and its cancellation update private totals and that the customer can still select an active branch. Take a Firestore export before moving production data.
2. Authenticate the migration process to the intended project. From the project directory, run the existing copy tool in dry-run mode and review the branch count.

       node functions/migrate_branch_metrics.js --project=<staging-project-id>

3. After confirming older Functions have stopped writing public totals, copy the legacy fields. The copy tool now preserves all public fields.

       node functions/migrate_branch_metrics.js --project=<staging-project-id> --apply

4. Run the parity check in staging and then in production after their respective migration and functional verification. Every branch must have a private metrics document. Each existing public financial field must match its corresponding private value. If private totals advanced after the legacy snapshot or aliases disagree, resolve the mismatch with verified financial records before cleanup.

       node functions/cleanup_public_branch_totals.js --project=PROJECT_ID

5. Only after staging **and** production verification, and with a fresh export, schedule a maintenance window for the separate destructive cleanup. The command requires explicit confirmation, checks every branch before the first removal, and rechecks each branch in its transaction. Review the table and stop on any mismatch. The command is provided for the operator and was not run.

       node functions/cleanup_public_branch_totals.js --project=PROJECT_ID --apply --confirm-public-financial-cleanup

The copy preserves newer private counters and retains the original public fields in `legacyPublic`. Keep the newer Functions running during recovery. Restore private metrics from the export if needed.

## Publish an Android update

1. Increase the version and Android build number in `pubspec.yaml`. Build the combined APK with the existing Food Fight release signing key using `flutter build apk --release --target-platform android-arm,android-arm64`.
2. Check the APK version and signing certificate with Android SDK Build Tools. Push the source commit to GitHub.
3. Publish a GitHub Release for that commit with a tag such as `v1.7.6` and a line such as `Build: 14` in the release description. Attach the signed APK and its matching `<filename>.apk.sha256` file, whose first field is the SHA-256 digest of the APK. Publish both files together.

Android checks the latest public release when Food Fight opens or resumes, subject to a six-hour throttle. Settings has a manual check and an opt-in automatic download switch. Food Fight verifies the checksum and Android handles the installation, including any required permission or confirmation.

Before publishing, test an upgrade from the previous signed build on Android. Keep the old app installed with a signed-in test account. In Settings, download the candidate update, grant install permission if prompted, and confirm the Android installer. After relaunch, verify the new build number and confirm that the existing session and local preferences survived. Use the same package ID and release signing key, with a strictly higher Android build number.

For GitHub Actions to build and publish on a version tag, configure the repository variable `ENABLE_ANDROID_RELEASE=true` and the protected repository secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` and `GOOGLE_SERVICES_JSON`. Keep those files and values out of Git.
