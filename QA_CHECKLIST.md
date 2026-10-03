# Food Fight — Production Quality Assurance & Compliance Checklist (v1.4.0+5)

This document details the rigorous quality assurance verification, architectural compliance, and production-readiness review for the **Food Fight** restaurant ordering and enterprise multi-branch management platform across all 5 user roles.

---

## 1. Role & Scope Verification (5 Distinct Roles)

- [x] **Super Admin (HQ)**:
  - Collapsible enterprise sidebar with branch overview, system KPI metrics, master store toggles, and theme switcher.
  - Multi-branch administrative management and sub-admin permission provisioning.
  - Global Loyalty Token rule configuration (welcome bonus, earn multiplier, redeem conversion rate).
  - Platform-wide Deals inspection and Review moderation across all 5 branches.
  - Full system audit and activity tracking.
- [x] **Admin (Branch Owner / Manager)**:
  - Collapsible professional sidebar (260px expanded / 72px collapsed) with live active order and unread chat badges.
  - Branch-scoped live order Kanban processing (Pending -> Confirmed -> Preparing -> Out for Delivery -> Delivered).
  - Branch Deals management: dynamic promotion creation with image uploads, percentage or fixed discount, and item bundling.
  - Option Templates & Menu management: centralized reusable Size Sets (S/M/L/XL) and Extras groups (Toppings, Dips).
  - Branch Customer Reviews moderation portal with visibility toggle and admin replies.
  - Customer ↔ Admin live split-pane chat with canned quick replies and inline order inspection.
  - Delivery zones and rider allocation.
- [x] **Sub-admin (Restricted Staff)**:
  - Branch-isolated operation restricted by granular permission flags (`orders`, `menu`, `chats`, `riders`, `reports`).
  - Protected sidebar and route guards preventing unauthorized navigation.
- [x] **Delivery Rider**:
  - Live task queue with real-time status progression (`pickedUp`, `outForDelivery`, `delivered`).
  - Real-time GPS location broadcasting to Firestore `rider_locations`.
  - Zero mock coordinates; real device location streams.
- [x] **Customer**:
  - Fast-food storefront with floating notch bottom bar, raised center cart button, and vertical category side-rail.
  - Branch selector across all 5 physical restaurant branches with address synchronization.
  - Live Admin Deals carousel with automatic bundle pricing.
  - Portion customizer with sizes and extras powered by reusable Option Templates.
  - Real reviews & 1-5 star ratings on Food Detail and post-delivery Order Tracking modal.
  - Loyalty token earn & redeem slider at checkout (1 token = Rs. 1).
  - Real-time two-way support chat with deterministic conversation IDs.

---

## 2. Zero Mock / Hardcoded Data Compliance

- [x] **Authentication**: Removed hardcoded demo credentials in `auth_service.dart`. Real Firebase Auth is enforced.
- [x] **Password Reset**: Removed demo bypass instructions in `reset_password_screen.dart`.
- [x] **Deals & Promos**: Replaced hardcoded sample deal cards with dynamic Firestore `deals` collection stream.
- [x] **Rider Coordinates**: Eliminated mock Karachi coordinates in `rider_dashboard_screen.dart`.
- [x] **Reviews**: Replaced dummy reviews in `food_detail_screen.dart` with live Firestore `reviews` collection queries.
- [x] **Coupons Cleaned**: Customer-facing coupon inputs replaced with automatic Admin Deals and Loyalty Tokens.
- [x] **Empty States**: Where data is empty, branded `EmptyStateView` components are displayed with actionable CTAs.

---

## 3. Runtime Error & Exception Eliminator

- [x] **`setState()` / `notifyListeners()` during build**:
  - Inherited `SafeChangeNotifier` across all providers.
  - Stream subscriptions and state notifications deferred to microtasks / `addPostFrameCallback`.
  - Disposed-guard pattern implemented on all 14 providers.
- [x] **Live Chat Firestore Permission Denied**:
  - In `chat_service.dart`, `getOrCreateChat()` uses deterministic document IDs (`support_{uid}_{branchId}` and `order_{orderId}`) with `SetOptions(merge: true)`.
  - `firestore.rules` updated so `allow read` succeeds on newly created or non-existent documents when participant condition is satisfied.
- [x] **RenderFlex Overflow Eliminator**:
  - Fixed-extent grids replaced with dynamic `SliverGridDelegateWithMaxCrossAxisExtent` and responsive aspect ratios.
  - Card components tested from 320px to 1920px widths and survive `textScaleFactor` up to 1.3 with zero pixel overflows.
- [x] **ListTile Material Ancestor Warnings**:
  - Wrapped every decorated container containing `ListTile` with transparent `Material` widgets.
- [x] **Missing Font Fallbacks**:
  - Configured `fontFamilyFallback: ['Noto Sans', 'Noto Color Emoji']` in `ThemeData` to eliminate missing glyph warnings.
- [x] **Numeric Type Cast Safety**:
  - Centralized `SafeConvert` helper applied to every model's `fromJson` to convert `num` to `double` safely.
  - Unit tests in `test/models_unit_test.dart` pass 100%.

---

## 4. Responsive & Adaptive Architecture

- [x] **Breakpoints**: Mobile (< 600px), Tablet (600–1024px), Desktop (> 1024px).
- [x] **Collapsible Sidebar**: Permanent 260px expanded / 72px collapsed on desktop with smooth animation; modal drawer on mobile.
- [x] **Adaptive Grids**: 1-column on mobile, 2-column on tablet, 3-4 column on wide desktop displays.
- [x] **Max Content Width**: Clamped to 1200px on desktop screens to eliminate stretched layouts.

---

## 5. Security & Data Integrity

- [x] **Firestore Security Rules**: Role-based access control for `super_admin`, `admin`, `sub_admin`, `rider`, and `customer` with strict branch isolation.
- [x] **Composite Indexes**: Declared in `firestore.indexes.json` for all multi-field queries.
- [x] **Storage Security**: Supabase RLS and policies restrict media uploads to authorized authenticated sessions.
- [x] **Loyalty Ledger Security**: Loyalty balances strictly updated through verified transactions with double-credit prevention.

---

## 6. Verification Results

- **`flutter analyze`**: **0 issues found** (0 errors, 0 warnings, 0 infos).
- **`flutter test`**: **97 / 97 tests passed** (100% test pass rate).
- **Web Build**: Release web artifact generated successfully at `build/web/`.
- **Android APK**: Release bundle compiled at `build/app/outputs/flutter-apk/app-release.apk`.
