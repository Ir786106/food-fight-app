# Super Admin sign-in and authorization audit

The configured project is `food-fight-bd72e`. Email sign-in first obtains a Firebase Auth UID, then reads `users/{uid}` from the Firestore server. The reported missing-profile message comes from that lookup returning no document. A document with a different ID cannot satisfy it even if its email matches. The Flutter role parser understands `super admin`, while current Firestore and backend authorization require the exact persisted value `super_admin`. That mismatch explains denied privileged access. The supplied profile's numeric `isActive: 1` is supported, and the Super Admin route has no branch requirement.

The signed-in Firebase CLI provided read-only access after the Admin SDK credential attempt failed. The legacy Super Admin Firestore document exists, both stored identity fields match its document ID, and its role is `super admin`. Firebase Auth has no account at that UID. Looking up the profile's stored email found exactly one enabled Auth account under a different UID. That identity has no canonical Super Admin claim, and Firestore returned HTTP 404 for `users/{actualAuthUid}`. The missing document at the authenticated UID is the verified cause of the profile error. No password sign-in was performed.

| Account | Firebase Auth at supplied UID | Firestore profile | Branch |
| --- | --- | --- | --- |
| Super Admin | Missing. An enabled account matches the profile email under a different UID. | Legacy role, numeric active flag, both stored IDs match the old document. The actual Auth UID's profile is missing. | Global access needs no branch once authorized. |
| Branch Admin | Present and enabled | Stored ID matches, `admin`, numeric active flag. Creation date is a zero placeholder. | No assigned branch in the profile. |
| Customer 1 | Present and enabled | Stored ID matches, `customer`, numeric active flag | No branch assignment required. |
| Customer 2 | Present and enabled | Stored ID matches, `customer`, Boolean active flag | No branch assignment required. |
| Rider | Present and enabled | Both stored IDs match, `delivery_rider`, numeric active flag and active status | No branch on the user profile. The separate fleet mapping remains unverified. |

The named Arifwala branch exists and reports active status. The live read did not test interactive logins, dashboard operations, or client permissions for these identities. There were no production writes.

## Local changes

| Files | Change |
| --- | --- |
| `lib/services/firebase/firebase_auth_service.dart` | Separates missing, denied, invalid, disabled, migration-required and transient profile failures. Fresh login and privileged restoration require a server profile. Customer restoration can still use an active customer document from the Firestore cache. |
| `lib/providers/auth_provider.dart`, `lib/models/user_model.dart` | Revalidates live profile changes, blocks inactive statuses even with a legacy active flag, and drops local access on a confirmed missing or invalid profile. |
| `lib/screens/splash/splash_screen.dart` | Removes direct dashboard routing from a cached role string and waits for the session provider to verify access. |
| `firestore.rules`, `functions/account_status.js`, `functions/index.js`, `functions/order_lifecycle.js`, `functions/platform_administration.js`, `functions/signed_image_upload.js` | Aligns explicit inactive status checks for privileged rules and affected server operations. |
| `functions/migrate_verified_super_admin.js` | Previews a single existing profile and prepares an approved, backed-up, one-field correction. It preserves IDs and claims. |
| `functions/migrate_verified_super_admin.test.js`, `test/auth_error_and_model_parsing_test.dart`, `test/rules/firestore_rules.test.js` | Regression coverage for authorized canonical roles, legacy numeric flags, inactive status, privilege checks and migration planning. |

## Existing rules versus supplied examples

The default deployed Firestore rules were last updated on October 12, 2026 UTC and differ from this checkout. The deployed source confirms overlapping branch and settings policies, authenticated branch-counter writes, client order creation, broad profile and GPS access, public general settings, client-created notifications and user-created loyalty transactions. Its Super Admin helper also accepts the custom claim as an alternative to the profile role. These production risks are still open.

The checked-in rules already use private branch metrics and server-owned order, loyalty, rider-assignment, and notification mutations. They limit tracking writes to the assigned rider and restrict chat and profile reads by participant, role and branch. The settings policy now uses one matcher with public reads for `global_settings` and `app_update` and Super Admin writes for the settings documents the previous policy allowed. No query or index changes were needed for this edit.

## Identity and screenshot follow-up

- Reviewed all 38 images in the WhatsApp archive. They show the rider callable error, unrelated rider-tab error banners, missing branch guidance, blank Maps, empty Admin menu, and Google and phone sign-in errors. The archive did not contain the reported Super Admin login error. The screenshots establish symptoms and do not identify current deployed rules or the production Auth UID.
- Flutter session verification and live updates compare any populated Super Admin `id` and `uid` fields against the authenticated UID before routing. The Firestore and callable privilege checks enforce the same rule. Historical documents with omitted or empty identity fields can still use the matching Auth UID and Firestore path.
- User-profile writes cannot replace persisted identity or scope fields, including supported legacy field names. Suspended or inactive customer profiles cannot be deleted by their owners and recreated as active. Ordinary profile edits remain available.
- Run the read-only account audit with `node functions/audit_account_profiles.js --project=PROJECT_ID --uid=UID_1 --uid=UID_2`. It reports row positions, identity alignment, active state, role classification and timestamp formats without returning UIDs, emails, phone numbers or token values. The Admin SDK command returned `app/invalid-credential` on this host. The live observations above came from the signed-in CLI using the [Auth account lookup](https://docs.cloud.google.com/identity-platform/docs/reference/rest/v1/accounts/lookup) and [Firestore document read](https://docs.cloud.google.com/firestore/docs/reference/rest/v1/projects.databases.documents/get) APIs.
- Legacy menu ownership, live Auth providers, Maps restrictions, Supabase URLs and FCM delivery still require a configured staging project and a device. The callable region remains `us-central1`. A fresh production Functions list returned zero deployments. The old signed artifact cannot validate these identity fixes.
- The live Auth configuration shows email/password enabled, Google enabled with an OAuth client configured, and Phone disabled. Phone is therefore blocked before SMS delivery. No provider settings were changed. Google still needs a signed-device sign-in check. [Project sign-in configuration](https://docs.cloud.google.com/identity-platform/docs/reference/rest/v2/projects/getConfig) · [Google provider configuration](https://docs.cloud.google.com/identity-platform/docs/reference/rest/v2/projects.defaultSupportedIdpConfigs/get)
- The Firebase Android app has both signing fingerprints for the prior signed release and neither fingerprint for this machine's debug APK. Use the authorized release signer for Google device tests, or register the debug fingerprints on staging after approval. Local Firebase configuration matches the project and package and includes a web OAuth client. Maps metadata and a local key are present. Maps API restrictions, billing and rendering remain unverified.

## Operator recovery and rollback

1. In Firebase Console, independently verify that the enabled Auth identity is the authorized platform owner. Matching the email is evidence of the mapping and does not prove authorization.
2. Take a full Firestore export for the same project using the [deployment runbook](DEPLOYMENT.md). Retain the completed operation receipt and a restricted copy of the legacy profile.
3. The latest live read found the profile at the existing Auth UID. The account is active and its stored identifiers match, but its role is still `super admin`. The applicable operation is the one-field correction using `migrate_verified_super_admin.js` against the existing Auth UID. Preview with `--project=PROJECT_ID --uid=VERIFIED_AUTH_UID`. Apply requires independently verified owner authorization and `--apply --confirm-authorized-uid=VERIFIED_AUTH_UID --backup-operation=EXPORT_RECEIPT.json`. The distinct-UID procedure below is historical for this incident and applies only when the target is absent.
4. Preview the distinct-UID recovery with the command below. The script checks the enabled Auth record, the explicit target UID on the legacy profile, and the missing target document. It creates nothing in preview.

       node functions/recover_verified_super_admin.js --project=PROJECT_ID --source-uid=LEGACY_UID --target-uid=VERIFIED_AUTH_UID

   After staging verification, independent ownership verification and explicit production approval from a project owner, use the same command with `--apply --confirm-target-uid=VERIFIED_AUTH_UID --owner-approval=APPROVAL.json --backup-operation=EXPORT_RECEIPT.json`. The approval JSON records the reviewed authorization and contains `project`, `sourceUid`, `targetUid`, `action` set to `create-super-admin-profile`, and `authorizationReference`. The file records external approval and does not establish ownership by itself.

   The transaction creates one canonical profile with the existing Auth UID in both identity fields. It copies the verified Auth email and optional legacy name, sets server timestamps, and omits the legacy device token, permissions, phone and branch. It preserves the old document, existing Auth account, UIDs and claims. It aborts if the source changed or the target already exists.
5. Verify the owner signs in to the global dashboard. Verify a separately approved branch assignment before enabling branch management for the ordinary Admin. Repeat customer and rider workflows in staging.
6. If rollback is approved, suspend the provisioned profile and end its sessions through the authorized account procedure. Keep the profile and its audit evidence. Reserve full-database restore for a reviewed incident procedure.

The previous signed Android candidate passed certificate and checksum verification against the preserved prior APK. It predates the authentication changes in this audit.

## Verification

- The full Flutter suite passed 385 tests, including the new Super Admin identity mismatch test.
- Twenty-two backend unit tests passed, including the redacted audit, migration planning, checkout, branch administration and signed image upload.
- Thirty-five Firestore emulator tests passed on retry. They covered conflicting identity fields, ordinary profile edits, inactive account protection, and the public updater configuration.
- Three order-lifecycle emulator tests passed, including authorization and duplicate acceptance coverage.
- The Android debug APK compiled with the identity changes. A subsequent splash change removed the analyzer's sole warning about returning a future from a try block. Fourteen targeted startup tests passed after that edit.
- Of the five supplied profiles, one creation timestamp was a zero placeholder and three profiles contained integer timestamps. The audit preserved them and did not infer timestamp units. No live profile was changed.
