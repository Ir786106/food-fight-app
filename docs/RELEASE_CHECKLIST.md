# Marketplace release checklist

- [ ] Stage the tenant schema and verify migration and recovery.
- [ ] Pass cross-tenant and user ownership rules tests and callable authorization checks.
- [ ] Verify customer quote, COD checkout, admin fulfillment, rider acceptance and delivery, tracking and ledger as one flow.
- [ ] Verify signed image uploads, private identity documents, maps, push and phone OTP.
- [ ] Verify Android and web builds, iOS on macOS, and English and Urdu responsive accessibility.
- [ ] Confirm launch city, rates, operator access and incident ownership.
- [ ] Obtain production deployment authorization.

## Local release verification

- [x] Full Flutter static analysis completed without issues.
- [x] Eight backend unit tests passed for checkout, customer phone profile creation and signed upload authorization.
- [x] All 361 Flutter tests passed.
- [x] All 16 Firestore emulator rules tests passed.
- [x] All three Firestore lifecycle tests passed, including customer quote, COD placement, kitchen preparation, rider delivery and cash settlement.
- [x] Customer, rider and admin debug web builds compiled.
- [x] All three optimized web builds verified at version 1.7.5+13. Each edition's HTML, bootstrap, bundle, manifest and version loaded over local HTTP.
- [x] Combined Android APK verified against the release certificate with v1 and v2 signatures. Package com.example.food_fight, version 1.7.5+13, minimum SDK 24, target SDK 36, arm64-v8a, armeabi-v7a and x86_64.
- [ ] Test a staged client on devices with a separate Firebase project and staging Supabase bucket. Real SMS, push, maps and signed uploads require provider setup and device verification.

Local builds are for verification. The order, OTP and upload callables must be available in the same Firebase environment as the client before live testing.
