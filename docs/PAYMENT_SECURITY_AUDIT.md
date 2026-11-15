# Food Fight payment and application audit

Baseline commit `3b544275adde1cefb773b418f73b8de6a63926e1`, version `1.8.5+22`, Firebase `food-fight-bd72e`, Android application ID `com.example.food_fight`, minimum SDK 24.

## Architecture and inventory

The combined app enters through `lib/main.dart`. Customer, rider and admin editions enter through `main_customer.dart`, `main_rider.dart` and `main_admin.dart`. The admin edition includes Super Admin. Provider owns client state, role guards sit in `lib/routes/app_routes.dart`, and service classes handle most external access. The [source inventory](SOURCE_INVENTORY.md) lists the screen, widget, provider, service, model and platform files. The [prior application audit](APPLICATION_AUDIT.md) and [authorization audit](AUTHORIZATION_AUDIT.md) track earlier findings.

Firebase Auth supplies identity. Firestore serves role-scoped reads and selected profile/catalog writes. The existing Firebase callables and the standalone Node server share checkout and lifecycle handlers. The Node server verifies Firebase ID tokens with revocation checks. The Firebase Admin SDK then performs pricing, order transitions, inventory and settlement in transactions. FCM notifications and scheduled rider-offer expiry still rely on deployed background infrastructure. Supabase is used for image storage, with signed upload authorization in the existing Functions code.

## Role and functionality status

| Role | Area | Status and evidence |
| --- | --- | --- |
| Customer | Home, menu, search, item options, favorites, cart, checkout, history, tracking, addresses, profile, saved wallets, reviews, loyalty, support, notifications | Implemented. COD calculation and order lifecycle have emulator coverage. Physical-device checkout, maps, OTP, Google sign-in, FCM and storage remain unverified on the live target. Saved wallets are account references. |
| Admin and staff | Dashboard, catalog, stock, kitchen and orders, dispatch, customers, chat, reviews, deals, hours, permissions, reporting | Implemented. Emulator coverage verifies order workflow and branch authorization. Each administration screen still needs a live smoke test with a scoped staff account. |
| Super Admin | Dashboard, branches, people, permissions, support, deals, riders, settings, audit logs | Implemented. Route and callable authorization regressions cover selected paths. Permissions and live metrics remain unverified against production. The Windows Firestore plugin supports count aggregates only. |
| Rider | Login, online status, offers, delivery, maps, history, earnings and settlement | Implemented with local integration coverage for assigned delivery through COD settlement. GPS, push delivery, background operation and payout reconciliation remain unverified on a device. |
| All roles | Android, Windows and responsive layouts | Existing widget suites cover selected device widths, text scales and themes. A screen-by-screen visual audit on every platform and viewport remains incomplete. |
| Customer | Card scanning, online card payment and secure manual card entry | Blocked by provider integration. Checkout exposes COD and an availability notice. No card capture, camera permission, custom OCR or live charges are enabled. |

## Issue register

| Severity | Component | Evidence | Resolution and status |
| --- | --- | --- | --- |
| High | Firestore saved payment methods | The owner could previously write arbitrary fields even though Flutter only saved wallet references. | Proposed rules allowlist wallet fields and validate the reference, reject a nonempty token and reject card fields. The default flag on legacy documents remains independently editable. Existing documents require a separate review. Production rules remain on hold. |
| High | Render and production order operations | Render workspace validation reported `need_payment_info`. Firebase production Functions could not be deployed on the Free plan. | Standalone Node gateway and Render Blueprint are available. No live endpoint or service account connection verified. Production COD and rider mutations remain blocked until cutover. |
| Medium | Checkout payment selection | The repository has COD logic and wallet references, with no configured merchant SDK or payment confirmation endpoints. | The checkout payment section shows COD and a localized online-payment availability notice. |
| Medium | Trusted backend shutdown | Startup previously accepted an unvalidated port and lacked an explicit shutdown handler. | Startup validates the port and drains HTTP connections on service shutdown, with a finite deadline. |
| Medium | API and client reliability | Existing checkout stores a request ID for retries and uses a bounded request timeout. Native push, host cold starts and multi-instance quotas have no live verification. | Keep the same checkout ID on retry. Add and verify production throttling and operational monitoring before opening the endpoint. |
| High | Node dependency lockfile | Initial install reported 17 advisories, including 3 high findings in transitive dependencies. | Compatible lockfile updates reduced the audit to 4 low and 8 moderate findings. Remaining remediation needs a separately tested Firebase Admin and email dependency upgrade. |

## Verification evidence

- Local Firestore emulator passed 38 rules tests, including the wallet reference allowlist, owner isolation and attempts to add card fields.
- Node backend unit suite passed 26 tests. Local Auth and Firestore lifecycle suite passed 3 integration tests, including the HTTPS-style gateway request flow over loopback.
- The previous Android review build passed signature and package checks. It is version `1.8.5+22`, API 24 minimum, and the signer SHA-256 matches Firebase registration. It predates the payment UI and wallet rules patch.
- The previous Windows installer passed GitHub Actions build and SHA-256 verification at the baseline commit. A production endpoint and installed-client verification remain open.
- Full-tree Dart format found two tracked tool files requiring format and one ignored scratch file under `build/`. The tracked tools were formatted without changing their behavior.

## Provider selection and capture boundary

- **Safepay** is a Pakistan merchant candidate. The provider documents merchant onboarding, a sandbox, hosted Express Checkout, tokenization and verified webhook delivery. Start evaluation with hosted manual entry because it can be opened from Android, Windows and Web with a browser. This audit did not find a vendor-confirmed Android or Flutter card camera scanner for this merchant integration. [Merchant onboarding](https://safepay.helpscoutdocs.com/article/50-starting-with-safepay-step-by-step-guide) · [Hosted checkout](https://safepay.alihamas.pk/docs/payments/get-started/express-checkout?platform=web) · [API reference](https://apidocs.getsafepay.com/) · [Webhooks](https://safepay.alihamas.pk/docs/developers/webhooks/overview)
- **Stripe** does not list Pakistan as a directly supported merchant country. A Stripe integration needs a legitimately eligible merchant and an approved market. [Country availability](https://stripe.com/global)
- Confirm the merchant's PCI DSS validation scope with the acquirer and provider. Use provider-hosted capture and preserve Food Fight's requirement to exclude PAN, PIN, CVV, track data and card images from client state, backend payloads, logs and storage. PCI DSS prohibits retaining card verification codes after authorization. [PCI SSC guidance](https://www.pcisecuritystandards.org/faqs/are-merchants-allowed-to-request-card-verification-codes-values-from-cardholders/)

## Provider integration contract

1. An authenticated customer requests a payment session. The backend validates branch, cart, discounts, stock, amount and currency and binds them to an expiring server-owned attempt and idempotency key.
2. The app opens an allowlisted provider-hosted HTTPS page or an approved native provider view. Only the provider offers camera scanning when documented and available for the merchant and target platform. Manual card entry stays in the provider UI.
3. The app receives an opaque attempt reference and displays pending confirmation. A redirect can return the user to checkout; verified provider status determines whether the payment succeeded.
4. The backend verifies webhook signatures using the provider's prescribed input, checks the amount, currency and attempt reference, and deduplicates provider events. One transaction applies the terminal payment state. Firestore clients cannot mark an order paid.
5. Review permission denial, cancellation, invalid/expired cards, declines, timeouts, duplicate callbacks, session interruptions and partial failures with approved provider test data in sandbox. Confirm that app telemetry and storage contain no card data.

## Deployment and release gates

- Verify the local Firestore rules patch with the rules emulator and an installed client. Preserve existing payment references.
- Connect the Render service after workspace verification. Store the production service identity in Render Secret Files and use a verified HTTPS origin. Confirm health and authenticated role behavior before releasing. [Deployment guide](DEPLOYMENT.md)
- Obtain an eligible merchant sandbox, approved SDK and platform support matrix, sandbox keys and webhook signing configuration before implementing or enabling cards. Run sandbox payment testing before requesting approval to enable live charges.
- Verify Android, Windows and Web builds plus Android upgrade, Windows install/launch, and role-based live smoke tests before publication.
