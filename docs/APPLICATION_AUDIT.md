# Food Fight application audit

Audit baseline `37059d2`, app `1.8.2+19`, Android package `com.example.food_fight`. This is a local repair checkpoint. Production data, rules, Functions, app registrations and package IDs were left untouched.

## Issue register

| Priority | Role and reproduction | Finding | Repair and verification |
| --- | --- | --- | --- |
| Critical | Rider accepts an assigned order | The production Functions listing for `food-fight-bd72e` returned zero deployments. The client calls `mutateOrder` in the default region, `us-central1`, and the source exports that callable. Other features that depend on deployed callables are also exposed to this gap. | Kept transitions server-authorized. Added clearer recovery messages. The emulator verified authorization and concurrent repeated acceptance. Live acceptance remains blocked. |
| High | Rider opens Earnings or Profile after a delivery query fails | Delivery, history, and profile shared a loading/error flag, so unrelated tabs could show a stale error or lose their content. | Split state by data source and scoped the error display by tab. Location problems now appear on delivery tabs. The targeted Flutter suite passed. |
| High | First-time customer signs in with Google | A new Firebase Auth account could reach the role lookup before a Firestore user profile existed. The reported native sign-in error has no device trace, so its cause is still unknown. | Create an absent first-time profile transactionally as customer. Read the role from the server and end the Firebase session on profile failure. Existing identities missing profiles require review of their original role. Native token exchange and onboarding remain pending on a signed device. |
| High | Customer selects phone sign-in | The client has number validation and maps provider errors. The configured project also has no deployed `completePhoneProfile` callable. | Input and error-mapping tests passed. Provider enablement, SMS policy, native app verification, real OTP, and profile completion require staging verification. |
| High | Unassigned Admin opens dashboard or Super Admin opens global Menu | An unassigned admin could see a headquarters heading. An initial global menu scope of `null` matched the uninitialized scope and could skip the first subscription. | Dashboard distinguishes headquarters, assigned branch and missing assignment. Menu starts the global subscription, reacts to scope changes, keeps scope on retry, and refuses an unassigned branch session. Admin order-scope tests passed. Live menu operations remain unverified. |
| High | Customer sees Maps or order tracking without live location | Android injects the key at build time. A historical tracking screenshot shows the “on the way” headline alongside “Assigned”. Current tracking source uses “Rider assigned” for that state and describes acceptance and collection in the timeline. | Confirm key, SDK and signer restrictions in staging and reproduce the exact build. Staged pin selection, location permissions, route and rider marker updates are pending. |
| Medium | Admin cannot find or edit a menu item that appears in a legacy path | The live menu stream reads `menuItems`. One-shot reads can fall back to `menu_items` when the canonical collection is empty. Writes target the canonical collection. | The subscription repair above is local. Compare both collections and ownership in staging before planning any reconciliation. |
| Medium | Customer sees “Malai boti chicken” with a pizza photo | The screenshot shows a possible image mismatch. The seed includes “Malai Booti Chicken Pizza”, and the screenshot does not identify a Firestore document. | Record the SKU, branch, display title, image URL and storage object on staging. Keep production images unchanged until the source of the mismatch is established. |
| Medium | Rider reviews COD or earnings totals | The screen has separate COD labels. Its figures derive from order totals and a settlement marker, and direct client reads of `codCollections` have no matching allow rule. | Settlement idempotence passed in the lifecycle emulator. Reconcile the displayed numbers against staged receipts and confirm the intended payout model. |
| Medium | Customer opens profile, support, loyalty or payment settings | Historical screenshots show spacing issues, overlapping navigation and an older saved-payment form. Screenshots alone do not identify the version or prove a live payment flow. | Responsive widget coverage exercised supported viewports, text scales, themes and navigation insets. Physical-device comparison, support and loyalty flows, and payment tokenization review remain open. |
| Medium | Admin, Rider or Customer encounters offline or empty data | Error handling and retry differ across screens. The rider banner was the confirmed cross-tab defect. | Scoped rider and menu error states and removed raw exception details from their affected actions. Broader offline, interruption and error review remains open. |
| Medium | Super Admin reviews branch isolation and sensitive data | Local rules deny tested cross-role and cross-branch requests. Production rules, private metrics parity, App Check and Supabase policies were not exercised. | Rules tests passed in the emulator. Complete the staged role matrix before release. |

## Changed files

| Path | Change |
| --- | --- |
| `lib/providers/rider_provider.dart` | Independent delivery, history and profile loading and error state |
| `lib/screens/rider/rider_dashboard_screen.dart` | Tab-specific feedback, safe delivery action errors and GPS retry handling that ignores callbacks from expired tracking sessions |
| `lib/screens/admin/dashboard/admin_dashboard_screen.dart` | Accurate branch assignment and headquarters states |
| `lib/screens/admin/menu/manage_menu_screen.dart` | Scope-aware subscriptions and retry |
| `lib/services/firebase/firebase_auth_service.dart` | First-time Google profile setup, authoritative role read and safer error handling |
| `test/responsive/device_matrix_test.dart` | Rider regression verifies delivery errors are absent from Earnings and Profile |
| `functions/order_lifecycle.emulator.test.js` | Concurrent acceptance and final assignment assertions |
| `lib/models/order_model.dart`, `lib/services/rider_service.dart`, `lib/widgets/common/session_bindings.dart` | Brace-only fixes for analyzer diagnostics |
| `docs/APPLICATION_AUDIT.md` | Findings, test evidence and staging checklist |

No dependencies or schema changes.

## Staging verification

1. Configure a separate Firebase project and verify the Android registration, Flutter options, Rules, Functions, indexes and App Check for that project. Follow [the deployment runbook](DEPLOYMENT.md). Confirm `mutateOrder` and `completePhoneProfile` exist in the configured callable region.
2. Use the actual signed staging APK. In Firebase Authentication enable Google for the staging project, register the APK signer's SHA-1 against the Android package, and refresh Android Firebase configuration. Test a new customer, a returning customer, a blocked account and a privileged user in the wrong app edition. [Firebase Google sign-in setup](https://firebase.google.com/docs/auth/flutter/federated-auth)
3. Verify the Phone provider, SMS region policy, package and signer fingerprints. Test configured fictional numbers first and then a permitted real number if staging supports SMS. Verify resend, invalid code, quota, cancellation and callable-backed profile completion. [Firebase phone sign-in setup](https://firebase.google.com/docs/auth/flutter/phone-auth)
4. Confirm Maps SDK for Android is already available in the staging Cloud project. Restrict the build key by Android package and APK signer SHA-1, restrict it to the required SDK, then provide it through `GOOGLE_MAPS_API_KEY`. Test search, pin selection, permission denial, address persistence and tracking on the signed APK. [Google Maps SDK configuration](https://developers.google.com/maps/documentation/android-sdk/get-api-key)
5. Place a COD order as a customer, move it through kitchen and rider, and compare customer, branch admin and Super Admin totals. Repeat with cancellation. Test two riders, duplicate acceptance, assignment to the wrong branch, suspended accounts and missing rider location.
6. Compare canonical and legacy menu documents on staging. Check private storage access, signed upload and image display for the exact affected item. Check profile, support, loyalty and payment flows with test accounts.
7. Compare the 37 supplied workspace screenshots with a fresh staging device capture. Cover handset and tablet insets, text scaling, Urdu RTL, light and dark themes, and landscape. ADB listed no connected device in the audit environment.

## Super Admin screenshot follow-up

The November 13 archive contains ten screenshots. The user confirmed that Super Admin sign-in now works. The screenshots show `getPlatformMetrics` failing on HQ and `mutatePlatform` failing during account management. The last production Functions listing returned zero deployments. Verify these two callables in staging before rollout. Dashboard metrics and account mutations remain server-authorized.

| Screenshot | Local change |
| --- | --- |
| HQ error and navigation, 1 and 10 | The initial error uses readable, scrollable copy and a retry button. A refresh failure preserves the last metrics and labels them as previously loaded. Zero orders remains a valid dashboard state. |
| Admin accounts, 6–9 | Account action errors and list errors are independent. The UI keeps one add-account control, shortens the header, uses a compact branch action, and improves role label contrast in dark mode. |
| Settings, 2–5 | Shorter delivery and cancellation labels, wrapping helper text, and a shorter save label fit narrow screens. Settings save errors and dashboard loading are independent. |

Five focused Flutter tests and six platform administration backend tests passed. The November 13 production Functions list again returned zero deployments. Physical-device layout and live callable behavior remain unverified. The previous signed APK predates the screenshot fixes. No production changes were made during the follow-up.

## Admin menu refresh follow-up

Pull-to-refresh now retains the selected branch and reads the same canonical collection as the management listener. The customer one-shot lookup retains its legacy fallback. A failed Firestore fetch is shown as an error instead of a successful empty list. Switching branches clears the old list and ignores late results from the previous scope. No live menu documents or product images were changed.

Two direct menu provider tests passed. They cover branch and collection selection and a late response after a newer refresh fails. Full Flutter analysis reported no issues and the full Flutter suite passed 389 tests. The six backend unit suites passed 26 tests. The tenant migration emulator passed both tests, covering the backup guard and fresh, legacy, partial, orphaned, repeated and paginated records. All 317 catalog keys and placeholders match across English and Urdu. App-wide translation and device review remain open. Flutter Doctor did not detect Visual Studio, and Inno Setup was not found in the standard locations, so the prior Windows installer does not cover the latest changes.

The supplied Firebase settings identify the production project. A separate staging project ID and backup bucket are still needed for the staging run. Production Firestore migration, rules deployment, callable rollout and public totals cleanup remain unexecuted. Follow the [staging runbook](STAGING_VERIFICATION.md) before authorizing production changes.

The local callable HTTP test passed against the Auth, Firestore and Functions emulators using an isolated demo project. It verified authorized metrics and branch status changes, denial for anonymous and customer requests, and denial after Super Admin suspension. The first parallel worker invocation timed out on this host. The single-worker rerun passed.

## Automated evidence

- Targeted Flutter tests passed 183 cases across authentication, app editions, admin scope and responsive layouts.
- The separately run rider widget regression passed and verified the tab-specific error behavior.
- The full Flutter suite passed 381 tests before the GPS follow-up. That checkpoint's analyzer reported 14 informational lints and zero warnings or errors. The follow-up addresses the reported lint locations.
- After the GPS follow-up, 176 responsive and authentication/model regression tests passed. On a signed staging build, still verify denied permission, disabled GPS, and starting another delivery while the previous location request is pending.
- The follow-up `flutter analyze --no-pub` completed with no issues. The focused GPS widget regression passed for disabled device location, denied permission on retry, and safe feedback when the native location service throws. The test used simulated platform responses.
- The local Android debug build completed and produced `build/app/outputs/flutter-apk/app-debug.apk`. Android SDK tooling reported package `com.example.food_fight`, version `1.8.2+19`, minimum SDK 24 and target SDK 36. The debug build kernel contains the GPS follow-up code. SHA-256 `e3c88cef7c1b378f1671dd45757012ce36118be4f7cf9b0f72303424d5a0703c`.
- ADB reported zero connected devices and the Android SDK had no emulator executable. The debug APK is suitable for a separate test install on a device without the signed app. Testing the in-app upgrade requires a higher build number signed with the same certificate as the installed release.
- Firestore rules passed 31 cases in the emulator.
- The Functions lifecycle emulator passed 3 tests, including the concurrent acceptance case.
- The checkout, platform administration and image signing backend unit tests passed 16 cases.
- The English and Urdu catalogs each had 317 matching keys. Catalog parity does not measure untranslated UI copy.

Production deployment and release remain pending staging and device verification. The earlier preview artifacts predate the changes in this audit.
