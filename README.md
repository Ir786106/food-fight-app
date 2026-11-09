<p align="center">
  <img src="assets/images/branding/food_fight_logo_icon.png" width="96" alt="Food Fight logo">
</p>

# Food Fight

Food Fight is a multi-branch food ordering and delivery platform built with Flutter and Firebase. Customers order from their local branch, kitchen staff prepare and dispatch orders, and riders handle pickup, delivery, and Cash on Delivery collection.

[Latest release](https://github.com/Ir786106/food-fight-app/releases/latest) · [Run the local demo](#run-the-local-demo) · [Deployment guide](docs/DEPLOYMENT.md)

## Install Food Fight

| Platform | Food Fight v1.8.0 |
| --- | --- |
| Android 7.0 or later | [Signed APK](https://github.com/Ir786106/food-fight-app/releases/download/v1.8.0/FoodFight_v1.8.0_release.apk) · [SHA-256 checksum](https://github.com/Ir786106/food-fight-app/releases/download/v1.8.0/FoodFight_v1.8.0_release.apk.sha256) |
| Windows x64 | [Food Fight Setup.exe](https://github.com/Ir786106/food-fight-app/releases/download/v1.8.0/FoodFight-1.8.0-Windows-x64-Setup.exe) |

Both installers contain the combined app, which opens the dashboard for the signed-in account’s role. On Android, open the APK and follow the system installation prompts. On Windows, run Setup.exe and launch Food Fight from the Start menu. The Windows installer is unsigned.

On Android, Food Fight checks for new releases when it opens or returns to the foreground. Users can also select **Settings → Check for Updates** or enable **Automatically download updates**. The app verifies the download against the release checksum before handing it to the Android installer.

## Storefront

The customer storefront adapts to the screen size. Mobile uses bottom navigation, category filters, a featured menu banner, and large dish photos. Desktop uses a branded sidebar and shows the live cart summary beside the menu on wide windows. Light and dark themes are available in Settings.

## Features

| Role | What you can do |
| --- | --- |
| **Customer** | Browse a branch’s menu, customize items, manage addresses, apply coupons and loyalty credits, place COD orders, track deliveries, leave reviews, and contact support. |
| **Kitchen and branch staff** | Manage menus, categories, deals, coupons and delivery areas. Accept and prepare orders, assign riders, confirm cash handover, handle support conversations, and export sales reports. Staff access is scoped by branch and permission. |
| **Rider** | Accept or decline delivery offers, confirm pickup and delivery, report location when permitted, and record COD collection. |
| **Super admin** | Manage branches and administrator accounts, configure platform settings, and review audit logs. |

Checkout uses a server-generated quote. Cloud Functions validate prices, availability, discounts, and delivery charges before creating an order. The backend also enforces order transitions, expires unanswered rider offers, and can dispatch to another available rider when the branch enables automatic dispatch.

**Payments** are Cash on Delivery. Saved wallet numbers are account references. The app currently processes cash collection and handover records.

**Sign-in and language** include email/password, Google sign-in, and Pakistani mobile SMS sign-in on configured platforms. English and Urdu are available, with right-to-left layout and translation coverage across selected customer and rider screens.

## Architecture

| Layer | Technology and responsibilities |
| --- | --- |
| Flutter client | Shared UI, role-specific routing, Provider state management, and light/dark themes. |
| Firebase Authentication | Account identity and sign-in. Role and branch authorization are enforced in the backend and rules. |
| Cloud Firestore and Functions | Live data, pricing and order mutations, dispatch, COD settlement, and audit records. Functions target Node.js 20. |
| Media and notifications | Firebase Storage and Firebase Cloud Messaging. Signed Supabase uploads for selected public images are optional. |
| Maps and location | Google Maps and device location on configured platforms. |

```text
lib/          Flutter screens, routes, models, providers, and services
functions/    Firebase callables, scheduled jobs, triggers, and backend tests
test/         Flutter unit, widget, workflow, and responsive tests
docs/         Setup, architecture, API, testing, and deployment guides
assets/       Branding and application images
```

The combined app starts from [lib/main.dart](lib/main.dart). The [customer](lib/main_customer.dart), [rider](lib/main_rider.dart), and [admin](lib/main_admin.dart) entry points restrict each build to its intended accounts and routes. These builds currently share the native app identifier and Firebase registration.

## Run the local demo

Use this path to try the app with seeded test accounts and Firebase emulators. It runs in Chrome and uses the isolated `demo-food-fight` project.

### Prerequisites

- Flutter SDK and Chrome. Development was verified with Flutter 3.47.2.
- Node.js 20 for Functions dependencies, Firebase CLI, and Java for the emulators.
- Android SDK and local Firebase configuration if you also plan to build the Android app.

Clone the repository and install dependencies:

```powershell
git clone https://github.com/Ir786106/food-fight-app.git
cd food-fight-app
flutter pub get
npm --prefix functions ci
```

In the first terminal, start the emulators:

```powershell
$env:FUNCTIONS_DISCOVERY_TIMEOUT = '60'
firebase emulators:start --config firebase.demo.json --project demo-food-fight --only auth,functions,firestore,storage
```

In a second terminal, seed the demo and start the customer app:

```powershell
$env:GCLOUD_PROJECT = 'demo-food-fight'
$env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9187'
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8687'
node functions/seed_local_demo.js

flutter run -d chrome --web-hostname 127.0.0.1 --web-port 8101 -t lib/main_customer.dart --dart-define=FOODFIGHT_LOCAL_DEMO=true
```

| Demo role | Email | Entry point | Port |
| --- | --- | --- | --- |
| Customer | `demo-customer@example.test` | `lib/main_customer.dart` | 8101 |
| Kitchen admin | `demo-admin@example.test` | `lib/main_admin.dart` | 8103 |
| Rider | `demo-rider@example.test` | `lib/main_rider.dart` | 8102 |

The emulator-only password is `FoodFight-Demo-123` for all three accounts. Start each role in its own terminal with the matching entry point and port so each browser origin has a separate session.

For a connected environment, configure your staging Firebase registrations, restricted Maps keys, and optional integrations using the [environment setup guide](docs/ENVIRONMENT_SETUP.md) and [deployment guide](docs/DEPLOYMENT.md). Keep signing keys, service accounts, provider secrets, and local configuration out of Git.

## Testing and releases

Run the following from the repository root:

```powershell
flutter analyze --no-fatal-infos
flutter test
node --test functions/checkout.test.js functions/signed_image_upload.test.js
```

See the [testing guide](docs/TESTING.md) and [deployment guide](docs/DEPLOYMENT.md) for rules tests and staging verification. The signed Android package and its published SHA-256 checksum have been verified. Installation and the full customer-to-kitchen-to-rider workflow on staging devices remain pending.

For a new release, increment the version and build number in [pubspec.yaml](pubspec.yaml). Build Android with the existing Food Fight signing key and publish the APK with its matching `.apk.sha256` file. The [Windows installer workflow](.github/workflows/windows-installer.yml) builds and packages the Windows x64 app from release branches. Attach the generated setup file to the same GitHub release. See the [Android release procedure](docs/DEPLOYMENT.md#publish-an-android-update) for tagging and update verification.

## Project documentation

| Guide | Contents |
| --- | --- |
| [Architecture decisions](docs/ARCHITECTURE_DECISIONS.md) | Design decisions and integration boundaries. |
| [API](docs/API.md) and [database](docs/DATABASE.md) | Callable functions, Firestore collections, and data ownership. |
| [Security](SECURITY.md) | Security policy and reporting. |
| [Progress](docs/PROGRESS.md) | Implemented features, verification results, and remaining staging work. |

Maintained by [Muhammad Irfan Waseem](https://github.com/Ir786106). This repository currently has no license file.
