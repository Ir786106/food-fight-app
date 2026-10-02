# 🥊 Food Fight — Commercial Digital Ordering & Multi-Panel Enterprise Platform (v1.3.0+4)

A complete, production-grade Flutter multi-branch fast-food ordering and enterprise management platform for **Food Fight Restaurant** (5 branches), featuring five distinct roles with role-based access control and branch isolation:

1. **Customer Storefront**: World-class fast-food ordering UX with floating notch navigation, raised center cart button, vertical category side-rail with curved indicator, dynamic Admin Deals carousel, size variant & sauce customization from reusable option templates, loyalty tokens redemption slider, Cash on Delivery checkout, 6-stage live GPS order tracking, real customer rating & review submission, and real-time support chat.
2. **Restaurant Admin Panel**: Collapsible professional desktop/tablet sidebar (260px expanded / 72px collapsed), active live KPI dashboard with unread chat & pending order badges, branch-scoped Deals management, Menu & Option Templates management with Supabase photo uploads, real-time order processing, review moderation, customer & rider management, and branch sales reports.
3. **Platform Super Admin Panel**: Enterprise HQ with collapsible sidebar, platform-wide intelligence (multi-branch overview, master kitchen switches, system revenue), global loyalty token configurations, admin provisioning & granular sub-admin permission delegation, platform-wide deal & review moderation, and full-spectrum audit logs.
4. **Delivery Rider Panel**: Dedicated rider console for active branch deliveries, live order status progression (`pickedUp`, `outForDelivery`, `delivered`), and real-time GPS location broadcasting.
5. **Sub-admin Role**: Restricted branch operators with permission-gated access (orders, menu, chat, reviews, riders).

---

## 🎨 Brand Design System (Sampled from Real Brand Logo)

Food Fight follows an authoritative, appetizing fast-food brand identity sampled directly from `food_fight_logo.png` & `food_fight_logo_icon.png`:

| Token Name | Light Theme Hex | Dark Theme Hex | Role & Usage Guidelines |
| --- | --- | --- | --- |
| `brandYellow` | `#FFD505` (`#FFD500`) | `#FFD505` | Primary buttons, active tabs, selected chips, badges |
| `yellowPressed` | `#E6BF00` | `#CCA800` | Pressed / hover state of brand yellow |
| `yellowSoft` | `#FFF3B8` | `#332B10` | Tinted containers, selected chip backgrounds |
| `yellowTint` | `#FFFAE0` | `#231E0D` | Subtle highlight rows, order context cards |
| `brandMaroon` (`brandBrown`) | `#6D2123` (`#5A1E1B`) | `#FFFFFF` / `#FFD505` | Headings, app bar titles, outline buttons, text on yellow |
| `maroonDeep` | `#4A1517` | `#1A0809` | Dark headers, gradients, pressed maroon |
| `background` (`cream`) | `#FAF7F2` (`#FFF8E7`) | `#140C0B` (`#1A0F0D`) | Scaffold background |
| `surface` | `#FFFFFF` | `#1E1211` (`#26160F`) | Cards, sheets, dialogs, input fill |
| `surfaceMuted` (`lightCream`) | `#F3EEE6` (`#FFF1C9`) | `#2A1A18` (`#33201A`) | Unselected chips, input fill, skeleton base |
| `border` | `#E7DFD3` (`#F0E3C0`) | `#3A2725` | Card borders, dividers, outlines |
| `textPrimary` | `#2A1415` (`#2B1412`) | `#F7EFE6` (`#FFF8E7`) | Headings and primary body copy |
| `textSecondary` | `#6B5B58` (`#7A6660`) | `#BCA9A3` | Subtitles, helper text, timestamps |
| `textMuted` | `#8F807C` (`#A8988F`) | `#8F7C77` | Placeholders, captions only |
| `tomato` (`ketchupRed`) | `#D9482B` (`#E63B2E`) | `#EF5350` | Discounts, favorite heart, sale ribbons |
| `mustard` (`cheeseOrange`) | `#CC9419` (`#F28C28`) | `#FFB74D` | Rating stars, warnings, accents |
| `lettuce` (`freshGreen`) | `#4C8C2B` (`#3FA34D`) | `#66BB6A` | Veg indicator, open status, success badges |

### 60-30-10 Design & Accessibility Rules

- **60% Neutrals**: `#FAF7F2` cream background and `#FFFFFF` white cards.
- **30% Maroon/Brown**: Authoritative typography, secondary buttons, outline buttons, and iconography.
- **10% Yellow & Accents**: Reserved for high-value CTAs, selected pill indicators, and discount tags.
- **WCAG 2.1 AA Contrast**: All text/background pairs exceed required contrast ratios (Maroon on Yellow > 7:1, White on Maroon > 9:1, TextPrimary on Background > 12:1). Verified by `test/wcag_contrast_test.dart`.

---

## 💬 Real-Time Customer ↔ Admin Chat Architecture

Food Fight includes a real-time messaging pipeline connecting customers directly with their chosen branch's administration:

1. **Deterministic Channel IDs**:
   - Order-linked: `order_{orderId}`
   - General support: `support_{customerId}_{branchId}`
2. **Customer Chat (`/chat`)**:
   - Live order context card with 1-tap navigation to order tracking.
   - Quick-reply chips ("Where is my order?", "Change address", "Wrong/missing item", "Cancel order").
   - Brand message bubbles (Brand Yellow for customer, White surface for admin).
   - Supabase photo upload for item verification and screenshots.
   - Resolved conversation banner with 1-tap reopen functionality.
3. **Admin Chat Console (`/admin/chats`)**:
   - Responsive layout: mobile list/thread navigation; desktop/tablet dual-pane split view.
   - Granular status management (`open`, `pending`, `resolved`).
   - Canned quick responses and inline "View Order" modal.
   - Branch scoping: Branch Admins and sub-admins with `chats` permission access only their branch's conversations.
4. **Push & In-App Notifications**:
   - Cloud Function `onChatMessageCreated` dispatches real-time FCM notifications.

---

## 🏗️ Architecture & Backend Stack

- **Primary Backend (Application Data & Auth)**: **Firebase**
  - **Firebase Authentication**: Customer, Staff, Admin, and Super Admin authentication with Google Sign-In support.
  - **Cloud Firestore**: Real-time streams and persistent collections for `users`, `categories`, `menuItems`, `orders`, `chats`, `chats/{id}/messages`, `deliveryAreas`, `coupons`, `settings`, `audit_logs`, and `reviews`.
- **Media & Image Storage**: **Supabase Storage**
  - Product photos, category banners, chat images, and user media uploaded directly to the Supabase `food-images` bucket using public token access.
- **State Management**: **Provider (`provider` package)**
  - Fully reactive architecture: `AuthProvider`, `CartProvider`, `ChatProvider`, `CategoryProvider`, `MenuProvider`, `OrderProvider`, `BranchProvider`, `CouponProvider`, `CustomerProvider`, `DeliveryAreaProvider`, `ReportProvider`, `AdminDashboardProvider`, `SuperAdminProvider`, `AdminAccountProvider`, and `AuditLogProvider`.
- **Security & Route Guarding**:
  - Enforced role guards in `AppRoutes`: `AdminRouteGuard` (restricts to `admin` / `super_admin`) and `SuperAdminRouteGuard` (restricts to `super_admin`).
  - Sensitive files and credentials strictly excluded from version control via `.gitignore`.

---

## 📁 Project Directory Structure

```
lib/
├── main.dart                          # App initialization (Firebase + Supabase + MultiProvider)
├── firebase_options.dart              # Firebase configuration
├── core/
│   ├── config/
│   │   └── supabase_config.dart       # Supabase URL, publishable key, bucket name
│   ├── constants/
│   │   ├── app_colors.dart            # Consistent design tokens
│   │   ├── app_constants.dart
│   │   ├── firestore_collections.dart # Firestore collection constants
│   │   └── firestore_fields.dart      # Document field constants
│   ├── theme/
│   │   ├── app_theme.dart             # Customer storefront theme
│   │   ├── admin_theme.dart           # Restaurant admin portal theme
│   │   └── super_admin_theme.dart     # Super admin governance theme
│   └── utils/
│       ├── validator_utils.dart       # Form validation logic
│       └── logger.dart                # Structured logging
├── models/
│   ├── user_model.dart                # User schema (id, name, email, phone, role, isActive)
│   ├── category_model.dart            # Category schema
│   ├── menu_item_model.dart           # Menu item schema (variants, addons, pricing, discounts)
│   ├── order_model.dart               # Order schema (orderNumber, status, items, subtotal, charges)
│   ├── cart_item_model.dart           # Cart item schema with selected variants & extras
│   ├── coupon_model.dart              # Coupon schema (flat/percentage discounts)
│   ├── delivery_area_model.dart       # Delivery area schema with pricing
│   ├── report_model.dart              # Sales analytics schema
│   └── admin/
│       ├── admin_account_model.dart   # Admin account management schema
│       ├── audit_log_model.dart       # Platform audit log schema
│       └── system_settings_model.dart # System-wide platform settings schema
│   ├── services/                      # Data services (Firestore, Auth, Supabase Image Storage)
├── providers/                         # Centralized ChangeNotifier providers
├── screens/
│   ├── auth/                          # Login, Signup, Forgot/Reset Password
│   ├── home/                          # Storefront home & navigation
│   ├── menu/                          # Menu listing with category filter
│   ├── cart/ & checkout/              # Cart & COD Checkout
│   ├── orders/                        # Order history & 6-stage live tracking
│   ├── admin/                         # Restaurant Admin screens (dashboard, orders, menu, etc.)
│   └── super_admin/                   # Platform Super Admin screens (dashboard, admins, settings, audit)
└── widgets/                           # Reusable UI components & design system elements
```

---

## 🚀 Quickstart & Setup Guide

### 1. Firebase Configuration & Deployment (Automated — No Manual Console Work)

The project is configured for Firebase project `food-fight-bd72e`.

1. **Configure Firebase Options** (Already generated via FlutterFire CLI):

   ```bash
   flutterfire configure --project=food-fight-bd72e
   ```

2. **Deploy Security Rules & Composite Indexes in a Single Command**:

   ```bash
   firebase deploy --only firestore
   ```

   *(Or individually: `firebase deploy --only firestore:rules` and `firebase deploy --only firestore:indexes`)*.
3. **Automatic Collections**:
   Firestore collections (`users`, `categories`, `menuItems`, `orders`, `deliveryAreas`, `coupons`, `reviews`, `notifications`) are created automatically the first time the app or admin writes to them. No manual collection creation in the console is required.

### 2. Supabase Storage Setup (For Media Assets Only)

Supabase Storage is pre-configured for food images, category icons, banners, and videos using the public bucket `food-images`:

- **Project URL**: `https://acevokhgphqrtvitukzv.supabase.co`
- **Publishable Key**: `sb_publishable_IAGhxF2xmeKLKOR5ZqITcw_ksW0Ghdc` *(safe for client apps; zero secret/service_role keys exposed)*.
- **Storage Bucket**: `food-images` (configured in `lib/core/config/supabase_config.dart` and `lib/core/constants/app_constants.dart`).
- **Media Upload Flow**: Every media upload uploads to `food-images` via `SupabaseStorageService`, generates an accessible public URL, and saves that URL into the matching Firestore document (`imageUrl` field). No text or application records are stored in Supabase.

### 3. Setting Up an Admin Account

To access the Admin Panel:

1. Register a new account inside the app via the **Sign Up** screen (or in Firebase Auth console).
2. Go to **Cloud Firestore** -> `users` collection -> locate your user document by UID.
3. Set the field `role` to string `"admin"` (default is `"customer"`).
4. When you log in with this account, the app will automatically route you to the **Admin Dashboard**!

### 4. Google Sign-In Platform Setup

Google Sign-In is integrated using Firebase Authentication's Google Provider:

1. **Android Setup**:
   - Generate your development SHA-1 and SHA-256 fingerprints:

     ```bash
     cd android && ./gradlew signingReport
     ```

   - In the [Firebase Console](https://console.firebase.google.com/), select project `food-fight-bd72e` -> Project Settings -> Your Android App.
   - Add both the **SHA-1** and **SHA-256** fingerprints.
   - Download the updated `google-services.json` and place it in `android/app/`.
2. **iOS Setup**:
   - `ios/Runner/Info.plist` is pre-configured with the reversed client ID URL scheme:
     `com.googleusercontent.apps.585587375994-5ak89r759o150jh93cubkp5o92b9l6q3`.
3. **Web Setup**:
   - `web/index.html` is configured with Google Client ID meta tag:
     `585587375994-h4ohhnrmellh0ooboa0gpdp9pq2v0m86.apps.googleusercontent.com`.
4. **Automatic User Provisioning**:
   - On first Google Sign-In, the app automatically creates the user document in `users/{uid}` in Firestore with `role: 'customer'`, ensuring seamless order placement and admin promotion.

### 5. Supabase Storage RLS Policies

To ensure authenticated app users can upload menu and profile pictures while keeping public read access active, run the migration in `supabase_storage_policies.sql` inside your **Supabase Dashboard -> SQL Editor**:

- Grants public read (`SELECT`) access on `food-images`.
- Grants authenticated users `INSERT`, `UPDATE`, and `DELETE` access.
- In `lib/main.dart`, Supabase client is initialized with a Firebase Auth ID token bridge so Supabase recognizes authenticated app requests.

---

## 🏃 Running the Application

```bash
# 1. Navigate to the project directory
cd food_fight

# 2. Get dependencies
flutter pub get

# 3. Verify tests and code quality
flutter test
flutter analyze

# 4. Run on your connected device, emulator, or Chrome
flutter run
```

---

## 📱 Features Breakdown

### 🥊 Customer Panel

- **Authentication**: Modern redesigned hero auth flow with email/password and **Continue with Google** sign-in. Password reset support.
- **Dark Mode**: High-contrast, WCAG-compliant dark theme with full support across all surfaces, cards, and text. Theme toggle available in Profile.
- **Home Screen**: Real-time category selector, search bar, active promotional banners, live food dishes from Firestore.
- **Item Details**: Photo from Supabase, spice level indicator, size selector, quantity adjustment, special instructions, add to cart.
- **Cart & Deals**: Adjust quantity, enter promo coupon code with instant validation (percentage, flat, or free delivery), automatic subtotal & delivery fee calculations.
- **Checkout**: Select delivery zone/area to apply accurate delivery charge, input house address, Cash on Delivery payment option.
- **Live Order Tracking**: Real-time 6-step status timeline (`Pending` -> `Accepted` -> `Preparing` -> `Ready` -> `Out for Delivery` -> `Delivered`).
- **My Orders**: Complete order history with status badges, item summaries, and polished empty states.
- **Profile**: Change details, upload profile picture to Supabase Storage, switch theme (Light/Dark/System), and switch to Admin panel if user is an administrator.

### 🛡️ Admin Panel

- **Dashboard**: Live KPI cards (Today's Sales, Orders Count, Pending Action, Delivery Zones), management shortcuts, and real-time live order stream with polished empty state.
- **Order Management**: Tabbed pipeline (`All`, `Pending`, `Accepted`, `Preparing`, `Ready`, `Out for Delivery`, `Delivered`, `Cancelled`). One-tap action buttons to advance status, or cancel with required reason prompt.
- **Menu Management**: Searchable menu list with category filters, image preview, active/inactive availability switch, and Add/Edit screen with camera/gallery photo upload to Supabase.
- **Category Management**: Add and organize food categories with photo upload and display order priority.
- **Customer Management**: View registered customer directory, search by name/email/phone, view lifetime orders and spent amount, and toggle active/blocked status.
- **Delivery Areas & Fees**: Create delivery zones with zone-specific delivery charges.
- **Coupon Management**: Create promo codes with percentage discount, flat discount, or free delivery, min order threshold, max discount cap, and validity duration.
- **Sales & Analytics**: Filter reports by Today, This Week, This Month, or All Time. View gross revenue, order completion statistics, and top-selling food rankings.
