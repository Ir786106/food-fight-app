# Changelog — Food Fight App

All notable changes to the "Food Fight" food delivery platform are documented here.

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
