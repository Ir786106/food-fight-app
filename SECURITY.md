# SECURITY.md — Food Fight App

## Threat Model

| Threat | Impact | Control |
|--------|--------|---------|
| Unauthorized role escalation | Critical | Server-side custom claims via Cloud Function; Firestore rules deny any client writes to `role`, `branchId`, `permissions`, `isActive` |
| Malicious APK distribution | Critical | SHA-256 verification before install; HTTPS-only from allowlisted GitHub CDN hosts; same-keystore signature enforcement |
| Token/credential exfiltration | High | `flutter_secure_storage` for all tokens; nothing sensitive in SharedPreferences; `FLAG_SECURE` on payment screens |
| MITM / cleartext traffic | High | `android:usesCleartextTraffic="false"` + `network_security_config.xml`; HTTPS enforced everywhere |
| Data backup leakage | Medium | `android:allowBackup="false"` + `android:fullBackupContent="false"` |
| Tampered update download | High | SHA-256 checksum verified before install; URL host allowlist; abort if hash missing |
| API key abuse | High | Firebase API key restricted by package name + SHA fingerprints in Firebase Console (manual step) |
| Anonymous Supabase storage writes | High | Policies updated to public-read only; admin writes via authenticated upload URL |
| Injection via user input | Medium | Input sanitized and length-limited on all user-facing fields |
| Privilege escalation via Firestore | Critical | Deny-by-default rules; role claims from server only; never trust client role field |
| App Check bypass (emulators) | Medium | Play Integrity in production; debug provider for dev builds; enforce in Firebase Console |

---

## Controls Implemented

### A. Authentication & Access Control
- **Custom Claims**: Role assignment only via Cloud Function `setUserRole` (super-admin callable); Firestore rules reject any client write to `role`, `branchId`, `permissions`, `isActive`.
- **Firestore Rules**: Deny-by-default. Each collection has explicit positive grants for each role. Negative cases tested with `@firebase/rules-unit-testing`.
- **Route Guards**: `AdminRouteGuard`, `SuperAdminRouteGuard`, `RiderRouteGuard` in `app_routes.dart` block unauthorized navigation client-side (defense-in-depth; not the primary control).
- **Login Throttling**: Firebase Auth enforces server-side lockout; client shows error messages without exposing counts.

### B. App Check & Backend
- **Firebase App Check**: Initialized in `main.dart` with `PlayIntegrity` for production, `DebugProvider` for debug builds.
- **Manual Step Required**: Enable enforcement for Firestore, Storage, and Functions in the Firebase Console → App Check → Enforce.

### C. Supabase Storage
- `supabase_storage_policies.sql` updated: anonymous `INSERT`/`UPDATE`/`DELETE` removed. Public `SELECT` only.
- Admin uploads should use a Cloud Function that verifies the admin role and returns a short-lived signed upload URL.

### D. Android Hardening
- `android:allowBackup="false"` ✓
- `android:usesCleartextTraffic="false"` ✓
- `network_security_config.xml` enforces HTTPS ✓
- `FileProvider` for APK installs (no world-readable paths) ✓
- `REQUEST_INSTALL_PACKAGES` permission for in-app updates ✓
- R8 minification + `shrinkResources` in release builds ✓
- `--obfuscate --split-debug-info` in release builds ✓
- `ProGuard` rules keep Firebase/Supabase/Flutter plugin classes ✓

### E. In-App Update Security
- Downloads only from HTTPS URLs on `github.com`, `objects.githubusercontent.com`, `release-assets.githubusercontent.com` ✓
- SHA-256 checksum verified before install; APK deleted if hash missing or mismatched ✓
- Every release signed with the SAME keystore (Android enforces signature match for updates) ✓

### F. Secrets Hygiene
- `.gitignore` excludes: `google-services.json`, `*.keystore`, `key.properties`, `*.env`, `supabase_config.dart`
- **Rotation required** if any key was previously committed (check with `gitleaks`)
- `firebase_options.dart` and `supabase_config.dart` contain runtime config; restrict API keys in respective consoles

### G. Dependencies
- Dependabot enabled for `pub`, `npm`, `github-actions` (`.github/dependabot.yml`)
- Run `flutter pub outdated` regularly and update to latest stable

### H. Privacy
- Terms of Service and Privacy Policy accessible from Settings
- Account deletion flow: TODO — implement Cloud Function to delete Auth user + Firestore data + Storage files

---

## Manual Steps Required in Consoles

### Firebase Console
1. **Enable App Check enforcement** for Firestore, Storage, and Cloud Functions:
   - Firebase Console → App Check → Firestore/Storage/Functions → Enable Enforcement
2. **Restrict Firebase API key** by package name (`com.example.food_fight`) and SHA-1/SHA-256 fingerprints:
   - Google Cloud Console → APIs & Services → Credentials → Restrict key
3. **Register SHA-1 and SHA-256 fingerprints** in Firebase project settings
4. **Deploy updated Firestore rules** (`firestore.rules`)
5. **Deploy Cloud Functions** (`functions/`)

### GitHub
6. Add secrets for release workflow:
   - `KEYSTORE_BASE64` — base64 of `release.keystore`
   - `KEYSTORE_PASSWORD` — keystore password
   - `KEY_ALIAS` — key alias
   - `KEY_PASSWORD` — key password
7. **Rotate any secrets that were previously in git history**

### Supabase
8. Apply `supabase_storage_policies.sql` to remove anonymous write policies
9. Consider adding RLS policies tied to Firebase JWT for admin writes

### Keystore Management
10. **Back up `release.keystore` and `key.properties` securely** (e.g., password manager, offline backup)
11. **Never commit keystore to git** (gitignored by `.gitignore`)
12. If keystore is lost, all installed APKs must be uninstalled before the new signed APK can be installed

---

## Residual Risks

| Risk | Status | Mitigation |
|------|--------|------------|
| App Check not enforced in console | **Requires manual step** | Documented above; enable enforcement in Firebase Console |
| Firebase API key not restricted | **Requires manual step** | Restrict by SHA + package name in Google Cloud Console |
| Supabase direct client write attempts | Mitigated | Policies applied (public-read only) + `getSupabaseSignedUploadUrl` Cloud Function implemented |
| No root/jailbreak detection | Low | Security recommendations documented for high-privilege devices |
| SHA-256 availability depends on GitHub release | Enforced | Verification strictly enforced; installation halts if checksum fails |
| First release-signed build requires manual uninstall | One-time | Documented in release notes and README due to signature transition |
| PII in Cloud Function logs | Remediated | Masking helpers implemented; Node 20 LTS runtime upgraded |

---

*Last updated: 2026-10-11 by automated security hardening run.*
