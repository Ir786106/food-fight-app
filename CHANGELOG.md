# Changelog — Food Fight App

All notable changes to the "Food Fight" food delivery platform are documented here.

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
