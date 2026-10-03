# Changelog — Food Fight App

All notable changes to the "Food Fight" food delivery platform are documented here.

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

