# Food Fight — Work Stream & Implementation Progress Checklist

Repository: `Food Fight` (com.example.food_fight)  
Version target: `v1.7.1+9`  
Initial commit inspected: `7af804e` (v1.7.0+8)  
Status: RESUMED & ACTIVE

---

## 1. Compatibility (All Android Versions, Lowest API Allowed)

| Item | Status | Verification & Code Evidence |
| :--- | :---: | :--- |
| **Pin minSdk explicitly in `android/app/build.gradle.kts`** (not `flutter.minSdkVersion`); document supported range in `README.md` | **DONE** | Explicitly set `minSdk = 24` in `android/app/build.gradle.kts` (line 34). Documented as Android 7.0+ (API 24 to 36) in `README.md` header and compatibility matrix. |
| **Guard version-dependent code** (`POST_NOTIFICATIONS` on 13+, `READ_MEDIA_*` vs `READ_EXTERNAL_STORAGE` maxSdk 32, location flows, foreground service types, scoped storage for APK downloads via `FileProvider`, Android 11+ `<queries>`, `coreLibraryDesugaring` if needed) | **DONE** | - `AndroidManifest.xml`: `READ_EXTERNAL_STORAGE` guarded with `android:maxSdkVersion="32"`, `WRITE_EXTERNAL_STORAGE` maxSdk 28, `READ_MEDIA_IMAGES` for API 33+.<br>- `POST_NOTIFICATIONS` runtime permission requested contextually in `OnboardingScreen` / after login.<br>- `<queries>` covers web, tel, mailto, maps, WhatsApp, and APK package archive installers.<br>- `FileProvider` configured with `file_paths.xml` for scoped APK install.<br>- `isCoreLibraryDesugaringEnabled = true` with `desugar_jdk_libs:2.1.4` in `build.gradle.kts`. |
| **Updater install flow**: Android 7 global Unknown sources vs Android 8+ per-app install permission; FileProvider URIs; friendly errors | **DONE** | In `MainActivity.kt`: `canRequestPackageInstalls` (returns true on API < 26, checks PackageManager on API 26+). `openInstallUnknownAppsSettings` opens `ACTION_MANAGE_UNKNOWN_APP_SOURCES` with package URI on 8+ and `ACTION_SECURITY_SETTINGS` on 7. `AppUpdateService` passes APK via FileProvider and surfaces bilingual error diagnostics. |
| **Handle missing/outdated Google Play services gracefully** (email login still works, no crash) | **DONE** | In `MainActivity.kt`: `checkGooglePlayServices` uses `GoogleApiAvailability`. In `FirebaseAuthService.dart`: Google Sign-In catches `SERVICE_MISSING`, `SERVICE_VERSION_UPDATE_REQUIRED`, `SERVICE_DISABLED`, `API_UNAVAILABLE`, and `12500`, mapping to friendly message to use Email & Password. Email login uses direct Firebase Auth REST/WebSocket, working 100% offline from Play Services. |
| **One consistent branded splash for all versions** with `androidx.core:core-splashscreen` + `values-v31` overrides; remove plain-color `launch_background` | **DONE** | - `values/styles.xml`: `LaunchTheme` inherits `Theme.SplashScreen` with `@color/splash_background` and `@drawable/splash_logo`.<br>- `values-v31/styles.xml` & `values-night-v31/styles.xml`: overrides `windowSplashScreenBackground` and `windowSplashScreenAnimatedIcon`.<br>- Plain `drawable-v21/launch_background.xml` removed; `drawable/launch_background.xml` updated to center `@drawable/splash_logo` over background color. |
| **Release APK ABIs: `arm64-v8a` + `armeabi-v7a`** | **DONE** | `android/app/build.gradle.kts`: `ndk { abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a")) }`. Validated by CI and badging checks. |
| **`./gradlew lintRelease` clean of real issues; compatibility matrix in README** | **DONE** | `lint { enable += setOf("NewApi", "InlinedApi", "ScopedStorage", "QueryAllPackagesPermission"); disable += setOf("PropertyEscape"); abortOnError = true }`. Compatibility matrix from API 24 to API 36 documented in `README.md`. |

---

## 2. "App Not Installed" (Release Signing & Integrity)

| Item | Status | Verification & Code Evidence |
| :--- | :---: | :--- |
| **Remove debug-key fallback in `build.gradle.kts`** (release must fail if keystore is missing); use EXISTING keystore only; enable V1+V2+V3 signing | **DONE** | In `build.gradle.kts`: `signingConfigs.create("release") { enableV1Signing = true; enableV2Signing = true; enableV3Signing = true }`. In `buildTypes.release`: explicitly verifies keystore exists or throws `GradleException`. Existing release keystore in `android/key.properties` preserved without regenerating. |
| **Expected release cert SHA-256** `18167d81cee7ef603131c59913ebd17b947038f9d5ebe198820fd6d044063a0b` (SHA-1 `b1882e4e150914051838acb1a59c0c90521f2921`); add `apksigner` verification to `.github/workflows/release.yml` | **DONE** | Added `apksigner verify --verbose --print-certs` step in `.github/workflows/release.yml` matching `EXPECTED_CERT_SHA256: "18167d81cee7ef603131c59913ebd17b947038f9d5ebe198820fd6d044063a0b"`, verifying V1 & V2 signatures, rejecting debug keys, and asserting `versionCode > 8`. |
| **Updater compares installed vs downloaded signing certificate** and shows an "uninstall once and reinstall" dialog on mismatch; map install failures to friendly messages; README troubleshooting section | **DONE** | In `MainActivity.kt`: `verifyApk` retrieves package signing certificates via `PackageManager.GET_SIGNING_CERTIFICATES` (API 28+) and compares SHA-256 with installed certificate. In `AppUpdateBottomSheet`: detects `ApkInstallStatus.signatureMismatch` and displays bilingual "Signature Conflict / Naye security key" dialog directing to release page. Troubleshooting section in `README.md`. |

---

## 3. Slow Startup (30+ s Before Splash)

| Item | Status | Verification & Code Evidence |
| :--- | :---: | :--- |
| **`main()`: only `ensureInitialized` + `Firebase.initializeApp` + theme load, then `runApp()` immediately** | **DONE** | In `lib/main.dart`: `main()` only runs `WidgetsFlutterBinding.ensureInitialized()`, `Firebase.initializeApp()`, and `themeProvider.loadThemeMode()`, then immediately calls `runApp(FoodFightApp())`. |
| **Non-blocking `AppBootstrap` in parallel with splash** (App Check, `Supabase.initialize`, FCM setup, update check) with per-task timeouts and try/catch | **DONE** | In `lib/core/bootstrap/app_bootstrap.dart`: `AppBootstrap.startBackgroundBootstrap()` executes via unawaited background future in parallel with splash; `_initAppCheck` (4s timeout), `_initSupabase` (5s timeout), and `_initFcmListeners` (4s timeout), each isolated in `try/catch`. |
| **Remove `FirebaseMessaging.requestPermission()` from startup** (ask only from onboarding primer / after login, Android 13+ only) | **DONE** | In `FcmService`: `initializeListenersOnly()` sets up background and foreground streams without requesting permissions. `requestNotificationPermission()` is invoked contextually during `OnboardingScreen` permission primer and post-login. |
| **Splash routing from `FirebaseAuth.instance.currentUser` + cached role**; a logged-in user is never sent to `/login` because of slow network; total cap ~4s; splash animation ~1.5s | **DONE** | In `SplashScreen`: 1400ms animation running in parallel with `_decideDestinationRoute()`. Uses `FirebaseAuth.instance.currentUser` + local `SharedPreferences` cached role. Network timeout or offline state routes to role home (`/home`, `/admin/dashboard`, etc.) rather than `/login`. Hard timeout cap at 3800ms. |
| **Lazy providers; update check deferred, 8s HTTP timeout** | **DONE** | Eager Firestore streams removed from constructors in `branch_provider.dart`, `category_provider.dart`, etc., loading on first access. Update check in `MainNavigationScreen` deferred 2.5s post-frame with Dio 8s connection timeout. |
| **Tests for splash routing and bootstrap; PERFORMANCE.md and SECURITY.md** (App Check enforcement must stay OFF while APK is distributed outside Google Play) | **DONE** | - `test/unit/splash_routing_decision_test.dart` (offline resilience & role routing)<br>- `test/unit/app_bootstrap_resilience_test.dart` (bootstrap timeouts & isolation)<br>- `test/unit/pre_install_verification_test.dart` (pre-install error mapping)<br>- `PERFORMANCE.md` includes before/after benchmarks and architecture breakdown.<br>- `SECURITY.md` contains explicit policy: App Check enforcement MUST remain OFF (unenforced) in Firebase Console for GitHub-distributed APKs. |
