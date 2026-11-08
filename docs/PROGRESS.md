# Implementation checkpoint

## Implemented locally

- Recorded the audit, requirements traceability, implementation plan and architecture decisions.
- Added a read-only quoteOrder callable using the same server pricing as placeOrder. Checkout confirms the server total before the first submission. Placement rechecks that total to the paisa. The accepted total and request ID persist for retries of the same checkout.
- Restricted checkout to COD and added inactive-profile checks. Firestore rules protect unrelated profiles from rider access and prevent blocked users from clearing their own block or deleting their profile.
- Scoped categories and both menu-item collections to branch-owned writes. Shared records remain readable and can be edited by super admins.

## Verification

- 4 Node checkout tests passed with an in-memory Firestore transaction substitute.
- 15 Firestore rules tests passed against the demo emulator, including cross-branch catalog access and profile protections.
- 18 focused Flutter tests passed after initializing the Flutter binding in the relevant test files.
- The initial full Flutter analyzer found four brace lint notices. The source now includes those brace fixes. The full Flutter test run exposed the same binding issue in other cart test files, which received the same setup fix. See TESTING.md for verification commands.

## Order fulfillment update

- Moved kitchen transitions, customer cancellation and rider assignment, acceptance, decline and delivery to the mutateOrder callable. Firestore denies direct client writes to orders and assignments.
- Validated branch staff permissions, active rider accounts, and one active delivery per rider. Declining an unaccepted offer returns it to the kitchen.
- Recorded confirmed COD collections in the same transaction as delivery and updated the order payment status. Rider-to-platform remittance and settlement remain open.
- The Firestore integration test passed with concurrent assignment, decline, pickup, COD confirmation and idempotent delivery. All 16 Firestore rules tests, 4 checkout tests and 19 focused Flutter regression tests passed.

## Dispatch and settlement update

- New offers expire after two minutes. The minute-based worker returns expired offers to Ready, and acceptance checks the deadline inside the order transaction.
- Added branch opt-in automatic dispatch and a Find available rider action in the kitchen. Automatic retries stop after three offers and skip the most recently declined or expired rider. Selection uses recent assignment history within a bounded pool. Distance-based dispatch and availability-triggered retries remain open.
- Added admin confirmation for full rider cash handover. The server checks the exact COD receipt amount and branch permissions, then records the first successful confirmation and mirrors the result on the order.
- All 6 backend tests and 16 Firestore rules tests passed locally. Coverage includes expiry, redispatch to another rider, unauthorized and incorrect cash confirmation, and idempotent settlement.

## Customer phone authentication

- Added Pakistani mobile SMS sign-in on Android, iOS and web. Email and Google sign-in remain available.
- The server requires a verified Firebase phone session, preserves existing customer profiles and rejects inactive or privileged accounts. A phone-only account can bootstrap a customer profile once.
- Existing email and Google accounts are not matched by a phone number stored in their Firestore profile. An existing Firebase-linked phone identity is required to sign in to the same account by phone.
- 15 focused Flutter tests and 5 backend tests passed. Live SMS, app verification and platform configuration still require staging tests.

## Signed Supabase public images

- Added signed uploads for new menu, category, profile and banner images behind a staging build flag. The server authorizes and scopes each path before returning an upload token.
- Added account upload quotas and a 2 MiB compressed JPEG limit. The bucket must enforce the real upload limit. Chat media remains in the existing private Firebase flow.
- All 8 backend tests and 4 focused Flutter tests passed. Signing tests use a fake Supabase response. Live bucket verification, private rider documents and Supabase cleanup remain open.

## Urdu interface and layout

- Added an English and Urdu selector in Settings. The app persists the device preference and restores it at startup.
- Added Flutter locale delegates so Urdu uses right-to-left layout and built-in Urdu controls. Localized navigation, settings and selected strings in login, checkout, cart, order history, tracking, profile and rider screens.
- Twenty focused Flutter tests passed, including saving the preference, switching Settings labels and mirroring customer navigation. Remaining English includes portions of these screens, admin workflows, server messages and user-entered or catalog content. Verify typography and layouts on staging devices before release.

## Role-specific Flutter entry points

- Added customer, rider and admin Flutter entry points using the shared app and Firebase configuration.
- Each entry point filters named routes by edition, checks a server-verified profile before admitting an account, and omits customer registration in the rider and admin builds.
- Seven focused Flutter tests passed, including route filtering and rejection of wrong-role login and restored sessions.
- Native app identifiers and Firebase registrations are currently shared. Independent mobile packaging, shared package extraction and staging deployment remain open.

## Local release verification

- Full Flutter analysis passed and all 361 Flutter tests passed.
- Eight backend unit tests, 16 Firestore rules tests and three Firestore lifecycle tests passed. The lifecycle coverage now includes quote and COD checkout through kitchen acceptance, rider delivery and settlement.
- Customer, rider and admin debug and optimized web builds compiled. The optimized builds passed the local HTTP asset check. The combined signed Android APK passed certificate and package verification. See IMPLEMENTATION_STATUS.md for artifact paths and checksums.

## Authenticated emulator verification

- Tested the checkout-to-settlement flow with password sign-in against Firebase Auth and authenticated HTTP requests to the Functions emulator backed by Firestore.
- Fixed Firestore FieldValue imports after the HTTP run exposed a runtime failure in order mutations and background handlers.
- All three lifecycle tests and eight backend unit tests passed. The HTTP case verified rejection of unauthenticated quote requests and customer settlement requests. The emulator used the installed Node 26 runtime. Staging runtime and device checks remain pending.

## Local Flutter demo

- Added a debug-web-only demo flag and local Firebase emulator configuration for Auth, Functions, Firestore and Storage. The demo uses its own Firebase project identity and skips the external app bootstrap.
- Added a guarded seed command for repeatable customer, kitchen and rider accounts, a branch, menu item and delivery area. The seed runs against the local demo only and keeps existing records.
- Compiled the customer debug demo build and passed ten focused Flutter tests for startup, role routing and demo safeguards. The seed ran twice successfully and an isolated authenticated checkout-to-settlement smoke test passed with the demo configuration. The HTTP case failed in a combined run and passed on its isolated rerun. Browser interaction still needs a smoke test.
- Verified that Firebase Storage in the demo accepts a customer's profile PNG and serves identical bytes. The emulator rejected a rider's attempt to write to the customer's profile and rejected a customer upload with a non-image content type.

## Next checkpoint

Remote staging and device verification are pending. The supplied food-fight-bd72e ID matches the existing default Firebase project. Use a separate staging project and an available device or Android emulator with the test procedure in DEPLOYMENT.md. Enable and verify signed uploads against the staging Supabase bucket. Finish Urdu coverage and verify RTL on devices. Verify role entry points on staging and complete separate native app registration and shared package extraction.
