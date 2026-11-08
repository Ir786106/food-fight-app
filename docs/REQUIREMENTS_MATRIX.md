# Requirements traceability

| Reference | Implemented locally | Remaining work or verification |
| --- | --- | --- |
| SAD §3 and master §2 | Customer, rider and admin entry points compile separately on web. Profile admission and routes are edition-scoped. | Separate native registrations, shared package extraction, Riverpod, GoRouter and TypeScript migration |
| SRS §3.1 | Existing Firebase sign-in, customer phone OTP, server-verified profile bootstrap and restricted role admission | Real SMS and platform verification, consistent claims and role revocation coverage |
| SRS §3.2 and API §§4.3–4.4 | Existing catalog and cart, server quote, COD confirmation and idempotent placement. Emulator covers quote through settlement. | Marketplace discovery and real device order tracking |
| SRS §§3.3–3.5 | Kitchen and rider order lifecycle, branch catalog rules, manual and branch automatic dispatch, expiry, COD receipt and settlement | Marketplace tenant migration, complete rider and platform approvals, nearest-rider selection and payout workflow |
| SRS §§3.6–3.7 | Existing FCM flow and opt-in signed Supabase uploads for public images | Staging notifications, live signed upload policies, private documents and cleanup |
| ERD and UI/UX | Branch schema, indexed dispatch, persistent Urdu selection and selected RTL screens | Marketplace schema migration and recovery, full Urdu coverage and device accessibility checks |
