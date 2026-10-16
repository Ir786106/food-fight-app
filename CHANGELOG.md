# Changelog — Food Fight App

All notable changes to the "Food Fight" food delivery platform are documented here.

## [1.7.4+12] — 2026-10-16

### Phase 0 — Audit, Project Hygiene & Dead Code Removal
- **Project Structure Cleanup**: Removed legacy duplicate root mirror directories (`models/`, `screens/`, `services/`, `providers/`) ensuring a clean, single-source-of-truth Flutter package.
- **Dead Code Elimination**: Permanently purged obsolete `auth_service.dart` containing mock demo credentials in favor of production `FirebaseAuthService`.

### Phase 1 — Security Hardening & Backend Data Integrity
- **Firestore Security Rules**: Hardened `firestore.rules` with strict branch isolation (`branchId` matching user custom claims for branch admins and staff), tamper-proof order status progression, and locked-down user roles.
- **Authoritative Order Calculation**: Deployed server-evaluated Cloud Function (`calculateOrderTotal`) verifying menu item pricing, addons, taxes, delivery fees, and loyalty discounts against backend documents, eliminating client-side price tampering.
- **Idempotent Loyalty System**: Implemented atomic, idempotent loyalty earn and refund ledger operations to prevent double-crediting.
- **Secrets & API Hygiene**: Scrubbed mock payment secrets (`pi_test_secret_...`) and hardcoded credentials; replaced with environment and runtime configuration.
- **GPS Location Integrity**: Removed fallback mock coordinates (`31.5204, 74.3587`), enforcing real hardware GPS position streams for delivery riders.

### Phase 2 — UI/UX Functional Bug Fixes (Customer & Admin)
- **Placeholder Emoji Cleanup**: Systematically eliminated placeholder `🥊` boxing glove emojis across 14+ customer and admin screens, dialogs, banners, models, and notifications.
- **Neutral Branded Image Fallback**: Replaced broken image placeholders with clean `Icons.fastfood_rounded` and subtle branded containers in `NetworkImageView`.
- **Dynamic System Strings**: Replaced hardcoded version and branch support strings; app version is resolved dynamically via `package_info_plus`, and branch phone/email reflect the selected physical branch.
- **Deduplicated Category & Sort Chips**: Separated sorting filters (Price, Rating, Delivery Time) from category chips and removed redundant emoji prefixes.
- **Modern Back Navigation**: Wrapped root and sub-screens in Flutter 3.x `PopScope` to prevent accidental exits and black-screen traps.
- **Google Maps API Integration**: Configured production API key meta-data in `android/app/src/main/AndroidManifest.xml` and `web/index.html`.
- **Admin Management Modernization**: Added date-range filtering, dynamic counter badges, and responsive layouts across Admin Orders, Categories, Dashboard, Chats, and Navigation Drawer.

### Phase 3 — Professional UI/UX System & Layout Overflows
- **Global Floating Navigation Fix**: Integrated `_TabNavigatorObserver` in `main_navigation_screen.dart` to automatically hide `FloatingNavBar` on nested detail flows (Checkout, Tracking, Loyalty, Food Detail) and the Cart tab, preventing overlay collisions with checkout and cart actions.
- **Dynamic Floating Cart Bar**: Dynamically adjusted bottom offset to `104.0 + safeBottom` when the bottom nav is visible and `18.0 + safeBottom` when hidden, completely eliminating overlap with the raised center bag button.
- **Canonical Design System**: Created `lib/core/theme/design_system.dart` standardizing color tokens, typography, spacing, and elevation tokens across customer and admin themes.
- **Zero-Overflow Device Matrix**: Automated testing across 10 device form factors (320px to 1920px) at 1.0x, 1.3x, and 2.0x font scaling factors with zero RenderFlex overflows.

### Phase 4 — Code Architecture, Modularization & Testing
- **Screen Modularization**: Decomposed oversized screens (>400 lines) into focused, single-responsibility widgets (`home_filter_sheet`, `home_navigation_sheet`, `home_section_header`, `food_detail_variant_selector`, `food_detail_addons_selector`, `food_detail_bottom_bar`, `tracking_timeline_card`, `checkout_preparing_branch_card`, `rider_status_toggle_header`, `super_admin_admin_role_chip`, `menu_item_availability_switches`).
- **Strict Lint Compliance**: Enabled strict linter rules (`avoid_print`, `cancel_subscriptions`, `close_sinks`, `prefer_const_constructors`), achieving 0 errors and 0 warnings on `flutter analyze lib/`.
- **Comprehensive Automated Test Suite**: Expanded test coverage to 330 unit, widget, and integration tests passing with 100% success rate.

## [1.7.3+11] — 2026-10-15

### Responsive Layout Engine & Breakpoint Architecture
- **Unified Responsive Framework**: Introduced `ResponsiveLayoutBuilder`, `ScreenType`, `DeviceMatrix`, and responsive utility helpers (`lib/core/responsive/`) providing consistent adaptive layouts across mobile, tablet, and desktop screens.
- **Role-Based Routing Architecture**: Implemented `UserRole` enum and `RoleRouter` to guarantee strictly segregated and type-safe role routing for customers, riders, admins, and super admins.
- **Customer Panel Mobile & Tablet Responsiveness**: Fully overhauled `CartScreen`, `CheckoutScreen`, `FoodDetailScreen`, and `OrderHistoryScreen` to support dual-column desktop/tablet master-detail views and scrolling, flex-safe mobile layouts without RenderFlex overflows.
- **Admin & Super Admin Panel Adaptations**: Responsive admin scaffold, navigation drawer, and order detail modals adapting seamlessly from 320px narrow mobile screens to 1080p wide monitors.
- **Zero-Overflow Device Matrix Test Suite**: Added automated responsive testing spanning 10 device viewports (320x568 up to 1920x1080) at 1.0x, 1.3x, and 2.0x font scaling factors with 100% pass rate.

## [1.7.2+10] — 2026-10-13

### Storage Provider Agnostic & Firebase Storage Primary
- **Provider-Agnostic Image Storage**: Added `AppImageStorageService`, `FirebaseImageStorageService`, and `CloudinaryImageStorageService` supporting smooth fallback and resilient upload/download paths.
- **Admin Image Re-uploader**: Added `reupload_missing_images_screen.dart` allowing admins to audit and restore menu item images directly in-app.
- **Image Compression**: Integrated client-side `ImageCompressor` to reduce image upload sizes and latency.

### Geolocation & Automatic Branch Selection
- **Automatic Geolocation Branch Selection**: Enabled GPS-based branch detection with distance radius, out-of-delivery warnings, and city picker dialogs (`CityPickerSheet`, `LocationPrimerDialog`, `LocationPickerMapDialog`).
- **Offline & Delivery Banners**: Added `OfflineBanner` and `OutOfDeliveryAreaBanner` to inform users of network drops and coverage limitations.

### Mobile Customer Panel Responsiveness & Code Audit
- **Zero RenderFlex Overflow**: Re-engineered customer home screen and product cards with responsive layout builders and flexible text wrapping, verified across screen widths (320dp to 412dp) and font scales up to 1.5x.
- **Test Suite Expansion**: Comprehensive unit and widget tests covering branch selection, image resolution, responsive mobile home, and contrast ratios (180 tests total, all passing).

## [1.7.1+9] — 2026-10-11

### Problem A — Installer Compatibility & In-App Updater Pre-Verification
- **V1+V2+V3 Signing Schemes**: Enabled full signing scheme compatibility (`enableV1Signing = true`, `enableV2Signing = true`, `enableV3Signing = true`) in `build.gradle.kts` for universal Android Package Manager installer compatibility.
- **Fail-Fast Signing Config**: The release build now strictly requires valid release keystore credentials via `key.properties` (or CI env secrets) and explicitly throws `GradleException` if missing; fallback to the debug key is permanently removed.
- **Pre-Install Package Verification**: Added native Kotlin PackageVerifier (`com.example.food_fight/package_verifier`) via MethodChannel that checks the downloaded APK's signing certificate SHA-256 against the currently installed app, checks for version downgrade, validates storage partition capacity, and checks unknown sources permissions prior to triggering the system package installer.
- **Bilingual Roman Urdu / English Error Dialogs**: If an update fails verification or signature mismatch is detected, displays a friendly dialog explaining: *"Yeh update ek naye security key ke saath sign ki gayi hai... / This update was signed with a different key. Please uninstall once..."* with a direct fallback button to open the GitHub Release page.
- **CI Certificate Guard**: `.github/workflows/release.yml` now runs `apksigner verify --verbose --print-certs` on built release APKs in CI, asserting that the SHA-256 fingerprint matches `18167d81cee7ef603131c59913ebd17b947038f9d5ebe198820fd6d044063a0b`, rejects `CN=Android Debug`, verifies `versionCode > 8`, `minSdk >= 24`, and validates `arm64-v8a` and `armeabi-v7a` universal release ABIs before publishing.

### Problem B — Startup Latency & Resilience Optimization (<1.5s First Frame)
- **Ultra-Lean `main()`**: Stripped all blocking initializations from `main()` before `runApp()`. Only `ensureInitialized`, `Firebase.initializeApp`, and theme loading execute sequentially. Cold start to first Flutter frame reduced from 30+s to **~1.1s**.
- **Non-Blocking Concurrent `AppBootstrap`**: Moved Firebase App Check (Play Integrity), Supabase Storage, and FCM stream listeners into a background orchestrator that executes in parallel with the splash screen via `Future.wait` with 4–5s per-task timeouts and resilient try/catch wrappers.
- **Notification Permission Primer**: Removed eager `requestPermission()` prompt from cold startup. Push notification permissions are now cleanly requested contextually during the Onboarding Permission Primer or after user login.
- **Cache-First Splash Routing**: Shortened splash animation to 1400ms and dropped unneeded delays. Splash route resolution runs concurrently using local `FirebaseAuth.instance.currentUser` and cached roles stored in `SharedPreferences`. Authenticated users are never logged out or redirected to `/login` due to slow network or offline mode. Total splash to routed screen capped under 3.8s.
- **Lazy Providers**: Removed eager Firestore queries from 10 ChangeNotifier provider constructors, preventing query contention during app launch.
- **Branded Native Splash**: Replaced plain color `launch_background.xml` with Food Fight's high-contrast brand icon on `#1C1C24` dark surface, supporting Android 12+ SplashScreen API.
- **Automated Tests**: Added 14 unit and widget tests covering bootstrap error isolation, pre-install signature mismatch mapping, and offline splash routing decisions.


### WS1 — Premium Onboarding Experience
- **New illustrations**: 4 custom AI-generated onboarding images in Food Fight brand palette (yellow/brown) replacing placeholder emoji.
- **Routing wire-up**: Splash → first-launch check (SharedPreferences `ff_onboarding_completed`) → `/onboarding` → `/login`. Returning users and logged-in users skip onboarding entirely. Admin/rider/super-admin logins never blocked.
- **"Replay App Intro"** option added to Settings screen to reset onboarding flag and re-enter the flow.
- **Tests**: `test/widget/onboarding_routing_test.dart` covers first-launch, returning-user, and replay-intro routing logic.

### WS2 — In-App Update System (GitHub Releases)
- **`AppUpdateService`**: Checks `GET https://api.github.com/repos/Ir786106/food-fight-app/releases/latest`; parses tag `vMAJOR.MINOR.PATCH+BUILD`; finds `.apk` and `.apk.sha256` assets; downloads with progress; verifies SHA-256 before installing; aborts if hash missing or mismatched; deletes temp file after install.
- **`AppUpdateProvider`**: Throttled checks (6h); Firestore `settings/app_update` for force-update; skip-version memory (24h); `AppUpdateBottomSheet` UI with progress bar, cancel, install, "Later", and "Open release page" fallback.
- **Security**: Only HTTPS URLs on `github.com`, `objects.githubusercontent.com`, `release-assets.githubusercontent.com` allowed; SHA-256 enforced; same-keystore Android signature check is automatic.
- **Settings**: "Check for Updates" and "App Version" (dynamic from `package_info_plus`) added to About section.
- **GitHub Actions**: `.github/workflows/release.yml` triggered on `v*` tags builds signed release APK, generates `.sha256`, creates GitHub Release. `.github/workflows/ci.yml` runs analyze + test on PR/push. `.github/dependabot.yml` enables automated dependency updates.
- **Tests**: `test/unit/app_update_service_test.dart` covers version comparison, tag parsing, URL allowlist, and release JSON parsing.
- **⚠️ Breaking**: First release-signed build — users with debug-signed APK must uninstall manually once.

### WS3 — Security Hardening
- **App Check**: Activated in `main.dart` with `PlayIntegrity` (release) / `DebugProvider` (debug); manual enforcement step documented in SECURITY.md.
- **Server-Side Role Control & Claims**: Cloud Function `setUserRole` sets Firebase custom claims server-side (callable, super-admin only); clients can never write role, branchId, permissions, or isActive.
- **Supabase Signed Uploads**: Implemented `getSupabaseSignedUploadUrl` Cloud Function; storage policies set to public-read only; anonymous writes eliminated.
- **Cloud Functions LTS & PII**: Upgraded runtime to Node 20 LTS; PII masking implemented across logs (masked phone numbers and emails); input validation and rate limiting.
- **Firestore Rules Hardening**: Added `settings/app_update` rule (public read, super-admin write); locked down `loyaltyAccounts` and transactions against client-side balance manipulation.
- **Rules Unit Testing**: Implemented `@firebase/rules-unit-testing` suite in `test/rules/firestore_rules.test.js` covering all 5 roles (super_admin, admin, sub_admin, delivery_rider, customer) and negative privilege-escalation cases; wired into GitHub Actions CI (`ci.yml`).
- **Android Hardening**: `android:allowBackup="false"`, `android:usesCleartextTraffic="false"`, `network_security_config.xml` (HTTPS only), `FileProvider` for APK installs.
- **R8 + Obfuscation**: `isMinifyEnabled=true`, `isShrinkResources=true`, custom `proguard-rules.pro`.
- **Dependabot**: `.github/dependabot.yml` for pub, npm, and github-actions ecosystems.
- **Secrets Hygiene**: `.env.example` template provided; strict `.gitignore` rules for keystores, keys, and cloud credentials.
- **SECURITY.md**: Full threat model, controls implemented, manual console steps, and residual risks.

## [1.7.0+7] — 2026-10-11

### Production Audit, Release Signing & Resilience Hardening

- **Android Permissions & Manifest (`AndroidManifest.xml`)**:
  - Added `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, and `POST_NOTIFICATIONS` to `android/app/src/main/AndroidManifest.xml` ensuring network calls, image loading, location tracking, and push notifications work in release APK builds.
- **Release Signing Automation (`build.gradle.kts`)**:
  - Configured release signing config in `android/app/build.gradle.kts` with `key.properties` and keystore fallback.
  - Kept sensitive keystores and properties strictly excluded from git.
- **Image Architecture & Resiliency**:
  - Replaced raw network images in chat and admin screens with `NetworkImageView` with image loading error diagnostics.
  - Hardened `MenuService` to query both `menuItems` and legacy `menu_items` collections seamlessly with automatic fallback.
  - Updated `supabase_storage_policies.sql` to require authenticated sessions for uploads, updates, and deletes while retaining public-read access.
- **Authentication Resilience & Error Wrapping**:
  - Wrapped `FirebaseAuthService.signIn`, `signUp`, and `signInWithGoogle` with 20-second timeouts, `AppLogger` real-error tracking, and exhaustive `AppException` translations (`permission-denied`, `network-request-failed`, `timeout`, `user-disabled`, data parse/type errors).
  - Guaranteed loading state resets in `finally` blocks to eliminate hung UI loaders.
- **Google Sign-In Hardening**:
  - Configured Android `serverClientId` (Web Client ID), safe cancellation handling, and automated creation of `users/{uid}` with customer role satisfying Firestore security rules.
- **Test Automation & Accessibility (Semantics & ValueKeys)**:
  - Added explicit `ValueKey`s and `Semantics` labels across all authentication inputs, buttons, visibility toggles, and terms checkboxes in `LoginScreen` and `SignUpScreen`.
  - Added `ValueKey`s to floating bottom navigation bar items (`tab_home`, `tab_orders`, `tab_cart`, `tab_chat`, `tab_profile`).
- **Validation & Form Controls**:
  - Added Pakistani phone number format validator in `ValidatorUtils` (`03xx` / `+923xx`, 11 digits).
  - Added password strength validator.
- **Testing & Verification**:
  - Created `test/auth_error_and_model_parsing_test.dart` covering error translation, phone and password validation, model parsing null-safety, and image fallback rendering.

## [1.5.0+6] — 2026-10-10

### Major Feature Upgrades & Production Hardening

- **Google Maps & Real GPS Tracking**:
  - Integrated `google_maps_flutter` with styled light/dark maps in `LiveTrackingMapWidget` streaming live rider coordinates.
  - Replaced hardcoded coordinates in `RiderDashboardScreen` with `geolocator` device GPS streaming to Firestore.
- **Interactive Analytics & Dashboard Charts (`fl_chart`)**:
  - Created `SalesTrendChart` (daily revenue and orders bar chart with interactive tooltips).
  - Created `OrderStatusDonutChart` (fulfillment status breakdown donut chart).
  - Created `BranchComparisonChart` (cross-branch revenue comparison for Super Admin HQ).
  - Integrated charts into `AdminDashboardScreen`, `SalesReportsScreen`, and `SuperAdminDashboardScreen`.
  - Added CSV analytics export in `SalesReportsScreen` using `csv` package.
- **Multi-Branch Fulfillment & Checkout**:
  - Added interactive branch selector card and modal sheet in `CheckoutScreen` synchronized with `BranchProvider` and `CartProvider.setBranchId()`.
  - Added customer Reorder button in `OrderHistoryScreen` repopulating cart from past orders.
- **Shimmer Skeleton Loaders**:
  - Created `ShimmerContainer`, `FoodCardSkeleton`, and `OrderCardSkeleton`.
  - Replaced generic progress spinners in `HomeScreen`, `MenuScreen`, and `OrderHistoryScreen` with responsive shimmer skeletons.
- **Hero Animation Polish**:
  - Unified hero tags across `ProductCard`, `FoodCard`, and `FoodDetailScreen` with custom hero tag support for seamless image transitions.
- **Persistent Favorites & Spice Customization**:
  - Backed favorites in `CartProvider` with `SharedPreferences` persistence.
  - Added 1–5 Spice Intensity selector (Mild to Atomic) in `FoodDetailScreen` appended to line item notes.
- **Backend Order Cancellation & Security Hardening**:
  - Enforced 5-minute cancellation window in `OrderService.cancelOrderByCustomer` and `OrderTrackingScreen`.
  - Hardened `firestore.rules` ensuring order total immutability, customer ownership validation, and branch update permission restrictions.
  - Switched order numbers to timestamp tail + entropy (`FF-$timeTail$random`) to eliminate collision risks.
  - Added `FcmService` background handler and token registration.
- **Option Templates Integration**:
  - Wired `OptionTemplateProvider` into `AddEditMenuItemScreen` for dynamic size and extras selection.
- **Quality & Verification**:
  - Added `test/phase2_features_test.dart` for cart math, order number entropy, and cancellation validation.
  - Full test suite passed (103/103 tests passing).
  - `flutter analyze` completed with **0 issues**.

## [1.4.0+5] — 2026-10-03

### Root Cause Navigation & Architecture Fixes

- **Tab Navigator Route Resolution (`MainNavigationScreen`)**:
  - Fixed `_buildTabNavigator()` which previously returned `rootScreen` for all route names, causing nested `Navigator.pushNamed()` calls to loop and rebuild the current screen.
  - Implemented proper route lookup via `AppRoutes.routes[settings.name]`, rendering the intended screen with `settings.arguments`.
  - Added `NotFoundScreen` fallback for unknown routes on both per-tab navigator and top-level `MaterialApp.onUnknownRoute`.
  - Set `rootNavigator: true` on logout, login, splash, and role guards (`AdminRouteGuard`, `SuperAdminRouteGuard`, `RiderRouteGuard`) to cleanly exit the customer tab shell.
  - Implemented 2-second double-back-to-exit snackbar on the root of the Home tab and nested backstack popping for tabs.
  - Center cart button in `FloatingNotchNavBar` now highlights with active yellow circle, maroon icon, and glowing halo when Cart tab is selected.

### Real Firestore Integration & UI/UX Audit

- **Home Screen & Category Rail**:
  - `CategoryRail`: Responsive width (`64–74dp`), 2-line centered labels with ellipsis avoiding truncation.
  - `ProductCard`: Increased horizontal card container heights from `240`/`250` to `290` to eliminate bottom button and price clipping.
  - Connected "See all" buttons to `/menu`.
  - Tapping loyalty gift pill navigates to `/loyalty`.
- **Loyalty Program (`LoyaltyTokensScreen` & `/loyalty`)**:
  - Created dedicated loyalty screen with live balance, dynamic tier badge (`Bronze Bite`, `Silver Snacker`, `Gold Gourmet`, `Foodie Champion`), earn/redeem rules, and real-time transaction history stream.
  - Dynamic token economics loaded from `settings/global_settings` (`welcomeTokens`, `loyaltyEarnRate`, `loyaltyRedeemRate`).
  - Automated welcome tokens credit on first sign-up and Google sign-in.
- **Robust Argument Handling & Error Views**:
  - `FoodDetailScreen`, `OrderTrackingScreen`, `RestaurantDetailScreen`, `OrderSuccessScreen`: Safely parse `ModalRoute` arguments (`FoodModel`, `OrderModel`, `RestaurantModel`, or IDs) and render friendly error states with back buttons instead of blank/crashing screens.
- **Order Tracking & History (`OrderHistoryScreen` & `OrderTrackingScreen`)**:
  - Corrected order status timeline mapping: `Pending (1) -> Confirmed (2) -> Preparing (3) -> On the Way (4) -> Delivered (5)`.
  - Fixed item plural formatting (`1 item` vs `2 items`).
  - Live GPS tracking map conditionally rendered only when a rider is assigned (`hasRider`), with "Assignment in progress" card otherwise.
  - Replaced floating lightning FAB with labeled "Support & Reorder" quick action pill.
- **Customer Chat Overhaul (`ChatService` & `CustomerChatScreen`)**:
  - Fixed `ChatService.sendMessage` using `batch.set(chatRef, ..., SetOptions(merge: true))` preventing crashes when creating conversations.
  - Retry button on failed messages now genuinely re-sends the failed message text.
- **Cart Persistence (`CartProvider`)**:
  - Added local serialization to `SharedPreferences` so customer carts survive app kills and restarts.
- **Profile Screen Dynamics (`ProfileScreen`)**:
  - Dynamic loyalty tier badge and live address count and labels.
- **Admin Navigation (`AdminDrawer`)**:
  - Redesigned header with brand maroon/yellow gradient and active item highlights.
- **Backend & Security**:
  - Cloud Functions: Server-side loyalty crediting on `delivered` status and refund on `cancelled` status in `functions/index.js`.
  - Updated `firestore.rules` covering all 12 modules with branch isolation and role enforcement.
  - Updated `firestore.indexes.json` with compound query indexes for orders, chats, deals, reviews, and loyalty transactions.
  - Created `DatabaseSeeder` in `lib/core/scripts/seed_database.dart` for initializing global settings, branches, option templates, and user migration.
- **Quality & Release**:
  - `flutter analyze` completed with **0 issues** across the entire project.
  - `flutter build apk --release` compiled successfully: `FoodFight_v1.4.0_release.apk` (64.0MB).

## [1.3.0+4] — 2026-09-30

### Customer UI/UX Premium Redesign

- **Floating Notch Bottom Navigation (`FloatingNotchNavBar`)**:
  - Implemented custom pill-shaped floating bottom navigation bar with `CustomPainter` (`_NotchedPillPainter`).
  - Elevated circular center action Cart button with live item-count badge counter and radiant ring halo (`_RingHaloPainter`).
  - Active tab indicators with filled brand icon and soft indicator dot.
  - Full light (pure white pill) and dark (near-black `#1E1211` pill) theme support with warm ambient drop shadows.
  - Scaffold `extendBody: true` integration with scroll bottom clearance across all main tabs.
  - Center button dedicates direct Cart access (`/cart`), eliminating duplicate mini cart bars on root tabs while preserving 4-tab `IndexedStack` and `_tabHistory`.
- **Design Dimensions Tokens (`AppDimens`)**:
  - Created `lib/core/constants/app_dimens.dart` defining 8-pt spacing grid, radii tokens (`radius8` through `radius28` and `radiusFull`), button heights, and soft warm shadow factories.
- **Home Screen & Food Card Redesign**:
  - Modularized `HomeScreen` from 1150 lines into dedicated components under `lib/widgets/home/` (`HomeHeader`, `HomeCategoryTabs`, `HomePromoCarousel`, `HomeFoodSection`).
  - Two-tone bold typographic header ("Find your" / "favourite foods 🥊").
  - Plain text category tabs with short rounded yellow underline indicator instead of heavy chips.
  - Redesigned `FoodCard` supporting circular food photo with soft drop shadow, price contrast (WCAG AA compliant), rounded-square yellow add-to-bag button, and vertical overflowing card variant `FoodCard.vertical(...)`.
  - Horizontal scrolling rails for "Popular" and "Recommended for you".
- **Food Detail Screen Overhaul (`FoodDetailScreen`)**:
  - Elevated circular Hero product image (diameter 230px) with multi-layer ambient drop shadow and `ClipOval` fallback emoji.
  - Three-dots overflow menu (`PopupMenuButton`) with "Share Dish" and "Report Issue" actions.
  - S/M/L rounded-square portion selector (selected = `brandYellow`, unselected = surface with subtle border) mapped dynamically to all `food.variants`.
  - Responsive quantity stepper (− 1 +) with yellow plus button accent.
  - Full-width dark pill "Add to bucket" sticky CTA with yellow bag icon block on the left and dynamic total price on the right.
  - Polished `ItemCustomizationBottomSheet` with 28px top corners, drag handle, and yellow-plus stepper.
- **Menu Screen Vertical Category Rail & View Toggle (`MenuScreen`)**:
  - Yellow vertical category side rail (`CategorySideRail`) with curved notch/bump active indicator and circular ring accent.
  - Permanent side rail on tablets and desktops (width ≥ 720px), collapsible with 1-tap animated toggle on mobile.
  - 1-tap Grid / List view toggle (`FoodCard.vertical` grid vs `FoodCard` horizontal list).
- **Orders Screen Speed-Dial FAB (`OrderSpeedDialFab`)**:
  - Curved animated speed-dial FAB on `OrderHistoryScreen` with quick actions for "Track Order", "Support Chat", and "Order Again".
- **Floating Cart Mini Pill (`FloatingCartMiniPill`)**:
  - Reusable dark pill with yellow bag icon block, item count, and running total on sub-screens (`RestaurantDetailScreen`).
- **Loading & Skeleton States**:
  - Added theme-aware `FoodCardHorizontalSkeleton` and `FoodCardVerticalSkeleton` matching new card geometries.

## [1.2.0+3] — 2026-09-30

### Brand Design System & Color Tokens (Part 1)

- **Single Source of Truth**: Established `lib/core/constants/app_colors.dart` as the sole design system palette token repository. Removed duplicate definitions in `lib/theme/app_theme.dart`.
- **Authentic Brand Palette**: Sampled directly from `food_fight_logo.png` & `food_fight_logo_icon.png`:
  - Brand Yellow (`#FFD505` / `#FFD500`) for primary buttons, highlights, chips, and selected states.
  - Brand Maroon / Brown (`#6D2123` / `#5A1E1B`) for authoritative typography, headings, secondary actions, and outlines.
  - Neutrals: Warm cream background (`#FAF7F2` / `#FFF8E7`), clean surface cards (`#FFFFFF`), muted containers (`#F3EEE6` / `#FFF1C9`), borders (`#E7DFD3` / `#F0E3C0`), and text hierarchy (`#2A1415`, `#6B5B58`, `#8F807C`).
  - Fast-food Accents: Tomato/Ketchup Red (`#D9482B` / `#E63B2E`), Mustard/Cheese Orange (`#CC9419` / `#F28C28`), Lettuce Green (`#4C8C2B` / `#3FA34D`).
  - Semantic & Lifecycle: Built `AppStatusColors` ThemeExtension supporting all 9 order lifecycle statuses with icon and soft tint pairings.
- **Accessibility & Contrast**: Verified WCAG 2.1 AA compliance across all main pairs (e.g., Maroon on Brand Yellow > 7:1, White on Maroon > 9:1, TextPrimary on Background > 12:1). Added automated test suite `test/wcag_contrast_test.dart`.
- **Default Light Theme**: Changed default mode in `lib/theme/theme_provider.dart` to `ThemeMode.light`. Polished dark mode remains toggleable in Settings.
- **Zero Hardcoded Customer Colors**: Completely replaced legacy hardcoded hex values (`0xFF121217`, `0xFF1D1D26`, `0xFF272734`) with semantic theme tokens across all customer screens.

### Customer Panel Redesign (Part 2)

- **4-Tab Navigation & Layout Hierarchy**: Modern bottom navigation (Home, Orders, My List, Profile) with per-tab Navigator preservation, back-button PopScope, and floating cart badge.
- **Home & Restaurant Experience**: Branch selector across all 5 branches driving live menus, dynamic categories, Firestore promotional carousels, and opening hour statuses. Restaurant Detail screen upgraded with Order, Review, and Information tabs plus sticky mini-cart.
- **Real Phone & Email Actions**: Replaced fake snackbar rows with real phone dialer (`tel:`) via `url_launcher` on Order Tracking and Profile, and real `mailto:` email support.
- **Empty States & Micro-Animations**: Enhanced `EmptyStateView`, `LoadingIndicator`, and shimmer skeletons for smooth, professional loading states.

### Real-Time Customer ↔ Admin Chat System (Part 3)

- **Data Model & Firestore Collections**: Added `chats/{chatId}` and `chats/{chatId}/messages/{messageId}` with deterministic IDs (`order_{orderId}`, `support_{customerId}_{branchId}`).
- **Customer Chat UI (`/chat`)**: Full-screen chat featuring order context cards with tracking navigation, brand-styled bubbles (Brand Yellow for customer, White surface for admin), quick reply chips, Supabase image attachments, auto-scroll, and resolved banner with 1-tap reopen.
- **Admin Chat Management (`/admin/chats`)**: Responsive split-view console (adaptive list and thread views), canned quick responses, "View Order" modal inspection, assignment toggles, and status workflow (Open, Pending, Resolved).
- **Branch Scoping & Role Security**: Branch owners and sub-admins with `chats` permission strictly see only their branch's conversations; Super Admin monitors all branches.
- **Security Rules & Cloud Functions**: Deployed least-privilege Firestore rules (Section 15), composite indexes, and Cloud Function trigger `onChatMessageCreated` for real-time FCM notifications.

---

## [1.1.0+2] — 2026-09-26

### Critical Bug Fixes (Priority 0)

- **Role-Based Firestore Security Rules Rewrite**: Rebuilt `firestore.rules` from scratch. The caller's role is authenticated from `/users/{uid}`, granting appropriate permissions to `admin` and `super_admin` for orders, settings, auditLogs, admins, riders, and dashboard metrics, while enforcing strict single-user ownership for `customer` documents.
- **Safe Type Conversion (`SafeConvert`)**: Resolved crashes caused by `type 'int' is not a subtype of type 'double' in type cast` and `type 'Timestamp' is not a subtype of type 'int'`. Added `SafeConvert.toDouble()`, `SafeConvert.toInt()`, and `SafeConvert.toDateTime()` across all models (`OrderModel`, `FoodModel`, `CartItemModel`, `RiderModel`, `SystemSettingsModel`, `AuditLogModel`, `AdminAccountModel`, `CouponModel`, `DeliveryAreaModel`, `AddressModel`, `CategoryModel`, `ReviewModel`, and `ReportService`).
- **Android Back-Button Navigation Stack**: Wrapped root customer navigation in `PopScope` with isolated `Navigator` keys per bottom-nav tab and tab history stack. Sub-screens pop first before switching tabs, and an exit confirmation dialog prevents accidental app termination from the home screen. Added parent route navigation guards for Admin and Super Admin drawers.

### Professional UI & Design Consistency (Priority 1)

- Standardized spacing, typography, and color tokens across Customer (`AppTheme`), Admin (`AdminTheme`), and Super Admin (`SuperAdminTheme`) design systems.
- Replaced truncated headers and text across Platform Settings, Audit Logs, and Order Tracking with scalable `FittedBox` responsive typography.
- Eliminated silent zero/blank fallbacks; replaced with real `LoadingIndicator`, `ErrorView` with retry triggers, and `EmptyStateView`.

### Responsive Layouts for Admin & Super Admin (Priority 2)

- Added adaptive layout breakpoints (`ResponsiveContainer`, `ResponsiveGrid`) for mobile and desktop/tablet viewports.
- Enhanced Admin Dashboard KPI grids, Super Admin metrics, and Order dispatch lists to natively adapt from single-column mobile view to multi-column desktop arrangements.

### Customer Panel Features (Priority 3)

- **Configurable Order Cancellation Window**: Added `orderCancellationWindowMinutes` system setting. Enforced both client-side (countdown timer in `OrderTrackingScreen` with modal confirmation) and server-side in `firestore.rules` (`request.time < createdAt + duration.value(settings.orderCancellationWindowMinutes, 'm')`).
- **Complete Profile Overhaul**: Replaced the previous flat form with a full-featured profile screen including user badge header, quick order shortcuts, saved addresses, payment methods, appearance theme toggle, notification preferences, security password reset, and role portals.
- **Tokenized Payment Method Management**: Built `PaymentMethodsScreen` supporting credit/debit cards (Visa, Mastercard) and mobile wallets (JazzCash, Easypaisa). Persists only tokenized gateway references and masked card identifiers with zero raw card or CVV storage.

### Multi-Channel Notifications (Priority 4)

- Configured Firebase Cloud Functions (`functions/index.js`) with triggers for `onOrderCreated` and `onOrderStatusUpdated`.
- Dispatches Push Notifications via FCM, Email Receipts via SendGrid, and SMS alerts via Twilio/local gateway, respecting system switches in Platform Settings.

### Fleet & Rider Management (Priority 5)

- Added `rider` role to `UserModel`, `AuthProvider`, and `AppRoutes` with dedicated `RiderRouteGuard`.
- Implemented `ManageRidersScreen` in the Admin panel for fleet registration, vehicle info, and activation toggling.
- Added 1-tap rider dispatch assignment modal in `OrderDetailModal`.
- Created `RiderDashboardScreen` console for riders to manage active delivery tasks and advance order status (`pickedUp`, `outForDelivery`, `delivered`).

### Live Order & Rider GPS Tracking (Priority 6)

- Implemented `RiderLocationService` broadcasting live GPS coordinates to Firestore (`orders/{orderId}/liveLocation/current`) during active deliveries.
- Created `LiveTrackingMapWidget` vector animation on `OrderTrackingScreen` displaying route polyline, live rider movement, radar pulse ring, and real-time ETA.
- Automatically halts GPS broadcasting upon order delivery or cancellation.

### Security Hardening (Priority 7)

- Deployed least-privilege `firestore.rules` and `storage.rules`.
- Third-party API secrets (Stripe, Twilio, SendGrid) secured exclusively in Cloud Functions configuration.
- Firebase App Check integration readiness configured.

### Production Enterprise Upgrade — Phases 1 to 10 (v1.3.0+4)

- **Phase 1: Zero Exceptions & Runtime Fixes**:
  - Eliminated `setState`/`notifyListeners` during build using `SafeChangeNotifier` across all 14 providers.
  - Resolved Chat permission-denied with deterministic IDs and `SetOptions(merge: true)`.
  - Replaced fixed-extent grid layouts with dynamic `SliverGridDelegateWithMaxCrossAxisExtent` surviving 320px to 1920px.
  - Wrapped 34 `ListTile` instances with transparent `Material` widgets to eliminate ink warnings.
  - Added glyph fallbacks (`Noto Sans`, `Noto Color Emoji`) to eliminate missing font warnings.
  - Eliminated all mock data from `auth_service.dart`, `rider_dashboard_screen.dart`, `reset_password_screen.dart`, and `food_detail_screen.dart`.
  - Model safe conversions (`SafeConvert`) applied across all models with passing unit tests.

- **Phase 2: Responsive & Adaptive Sidebar Architecture**:
  - Implemented `AdminCollapsibleSidebar` and `SuperAdminCollapsibleSidebar` (260px expanded / 72px collapsed).
  - Real-time badges for pending orders and unread customer messages.
  - Built unified `AdminScaffold` and `SuperAdminScaffold` supporting adaptive viewports.

- **Phase 3: Customer UI/UX Redesign**:
  - Floating notch navigation bar with elevated center cart button and ring halo.
  - Vertical yellow category side-rail with curved indicator.
  - Real reviews from Firestore wired directly on Food Detail and post-delivery review dialog.

- **Phase 4: Admin Deals Module**:
  - Removed legacy coupon code inputs from customer storefront.
  - Built full `DealModel`, `DealService`, `DealProvider`, and `ManageDealsScreen` for branch-scoped and platform-wide deals.
  - Live customer Deals carousel with automatic bundle pricing.

- **Phase 5: Loyalty Tokens System**:
  - Built `LoyaltyModel`, `LoyaltyService`, and `LoyaltyProvider`.
  - Automated welcome bonus (50 tokens) upon registration.
  - 1 token earned per Rs. 100 spent on delivered orders.
  - Interactive token redemption slider at checkout (1 token = Rs. 1).
  - Full audit ledger in `loyaltyAccounts` and `loyaltyTransactions`.

- **Phase 6: Reviews & Moderation**:
  - Implemented `ReviewService`, `ReviewProvider`, and `AdminReviewsScreen`.
  - Customer 1-5 star ratings and comments with live item aggregate calculations.
  - Admin moderation portal with visibility toggling and administrative replies.

- **Phase 7: Option Templates**:
  - Centralized reusable size sets (4-size S/M/L/XL, 3-size M/L/XL, custom) and extras groups (Toppings, Dips).
  - Linked to menu items without redundant re-entry.

- **Phase 8 & 9: Security & Live Chat**:
  - Branch-routed support chat with deterministic conversation IDs.
  - Deployed comprehensive `firestore.rules` covering all 5 roles with branch isolation.
  - Validated composite indexes in `firestore.indexes.json`.

- **Phase 10: Verification & Build Artifacts**:
  - `flutter analyze`: 0 issues found!
  - `flutter test`: 97 / 97 tests passed!
  - Release Web build generated at `build/web/`.
  - Release Android APK generated at `build/app/outputs/flutter-apk/app-release.apk`.
