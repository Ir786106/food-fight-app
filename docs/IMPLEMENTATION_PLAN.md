# Marketplace implementation plan

1. Capture the current baseline and preserve the existing working tree.
2. Reuse server pricing for a read-only quote, wire it into COD checkout and verify price drift and replay handling locally.
3. Define tenant membership and staged migration fixtures. Harden catalog, user reads, role revocation and order state changes with emulator tests before changing live rules.
4. Extract shared Flutter infrastructure and migrate role entry points and routes incrementally. Add OTP, restaurant catalog and account flows.
5. Implement rider onboarding, assignment offers, expiration, transactional pickup and delivery, COD and earnings. Verify full customer, restaurant and rider flow.
6. Add authorized Supabase uploads, private identity storage, FCM and device maps. Finish super-admin approvals and audit coverage.
7. Verify cross-tenant access, English and Urdu layouts, device and web builds and staging runbooks before secondary features and release.
