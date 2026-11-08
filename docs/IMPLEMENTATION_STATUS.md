# Food Fight implementation and release status

The local project now has a verified backend order flow and three compilable Flutter web entry points. The local release artifacts passed verification. Production readiness still depends on separate staging configuration and real-device verification.

## Implemented changes

| Area | Changes | Verified locally |
| --- | --- | --- |
| Customer checkout | Added a server-generated COD quote and a confirmation dialog. The placement transaction recalculates price to the paisa, saves the order once per checkout request, and commits stock, coupon and loyalty changes together. | Backend checkout tests and Firestore lifecycle test |
| Security | Scoped branch catalog writes, restricted rider access to unrelated profiles, protected blocked profile fields and made order and rider assignment documents server-write-only. | Firestore emulator rules tests |
| Kitchen and rider workflow | Moved status changes, cancellation, assignment, acceptance, decline, pickup and delivery into the server transaction. Added order history and audit entries for the actions. Concurrent assignment is limited to one active order per rider. | Lifecycle tests for invalid transitions, access and competing assignments |
| Dispatch and settlement | New offers expire after two minutes. Enabled branches can automatically select another eligible online rider. Added the kitchen option to find a rider and confirm receipt of cash. COD collection and settlement are recorded once. | Emulator tests for expiry, redispatch, incorrect cash amounts and repeated confirmation |
| Phone OTP | Added customer sign-in for Pakistani mobile numbers. Verified Firebase phone sessions can bootstrap a customer profile. Staff and inactive profiles cannot use the customer OTP flow. | Flutter input and backend profile authorization tests |
| Image uploads | Added server-authorized Supabase upload tokens for public product, category, profile and banner images. The server chooses the path and enforces account quotas. The rollout is behind a staging build flag. Chat attachments use the existing Firebase participant-scoped storage. | Backend authorization and Flutter routing tests with a simulated Supabase response |
| Urdu and RTL | Added a persistent Settings language selector, right-to-left direction in Urdu, and Urdu labels for navigation and selected customer and rider screens. | Flutter tests for preference restore, direction and tab selection |
| Role editions | Added customer, rider and admin Flutter entry points with filtered routes and server-verified account roles. The admin edition includes branch admins, sub-admins, staff and super admins. | Flutter routing tests and three distinct debug web builds |
| Release verification | Ran the complete local test suite and added an emulator case that starts at a customer quote and ends at kitchen cash settlement. | Clean Flutter analyzer, 361 Flutter tests, 8 backend unit tests, 3 lifecycle integration tests and 16 rules tests |

## Build and deployment status

| Target | Status |
| --- | --- |
| Customer debug web | Compiled locally |
| Rider debug web | Compiled locally |
| Admin debug web | Compiled locally |
| Customer optimized web | Verified locally |
| Rider and admin optimized web | Verified locally |
| Signed combined Android release APK | Verified locally with the expected certificate, v1 and v2 signatures, version 1.7.5+13, SDK 24 minimum and SDK 36 target |
| Independent native apps | Separate app identifiers, signing and staging Firebase registrations are required |
| Live staging | Pending a separate Firebase project, configured providers and test devices |
| Production | No deployment performed |

The emulator integration now also verifies Firebase password sign-in and authenticated callable HTTP transport against local Firestore. It covers quote, idempotent placement, stock, preparation, assignment, delivery and settlement. The HTTP run exposed a Firestore FieldValue import problem in the Functions runtime, which was corrected and retested. Device interaction, tracking, maps, push and real SMS still require staging verification.

## Verified local artifacts

| Artifact | Path | SHA-256 |
| --- | --- | --- |
| Combined Android release APK | build/app/outputs/flutter-apk/app-release.apk | e2fcc6801831f3fcfea9c92760c393b0b13a76df2889ffae1337acea47e3a1cb |
| Customer web bundle | build/release-web/customer/main.dart.js | c328ada1f5cdc4d072e0c51f1bb7eb5533d822a639d266aff204c904a0828d2e |
| Rider web bundle | build/release-web/rider/main.dart.js | d2045d5b4c0ca3136148ab4eecf253d057bf91ae9db9f3c80b0a00faf8d5d47b |
| Admin web bundle | build/release-web/admin/main.dart.js | ff7040bec2a4c29adf13e91709f9da54479fe98db62fd16b119a2c66c6a1b93c |

All three web editions served their HTML, bootstrap, JavaScript, asset manifest and version files over local HTTP. Browser interaction and device installation are separate checks. The configured Firebase project is food-fight-bd72e, and the device check found no connected Android device or configured emulator.

## Remaining scope

- Set up a Firebase staging project distinct from the current default, stage the matching client, functions, rules and indexes, and test with real customer, kitchen and rider sessions.
- Verify actual Supabase upload and read policies with staging credentials. Private rider documents, server-side content inspection and orphan cleanup remain open.
- Finish Urdu translation coverage and device checks for fonts and right-to-left layout.
- Complete marketplace tenant schema migration, full rider and restaurant approval workflows, role revocation coverage and rider earnings and payouts.
- Complete distance-based dispatch and availability-triggered retries. The current automatic selector uses recent assignment history within the branch.
- Complete independent native app registration and packaging, extract the shared package, and migrate Provider, named routes and JavaScript Functions to the target Riverpod, GoRouter and TypeScript architecture.
- Verify the release on real devices in staging before distribution. iOS build verification requires a macOS signing environment.

See RELEASE_CHECKLIST.md, DEPLOYMENT.md and ENVIRONMENT_SETUP.md for the release gates, build commands and staging procedure.
