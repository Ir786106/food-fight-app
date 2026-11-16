# Food Fight 1.8.5+22 release audit

The 31 screenshots were reviewed in ZIP entry order. Each row gives the screen to open, the observed behavior and what still needs to be verified. Screenshots show build 20. Local signed build 21 already exists. GitHub main was at `806898b`, with version `1.8.0+17`. The latest stable release is v1.8.0 and the newest preview is 1.8.2+19. Version 1.8.5+22 is reserved for this review branch.

| Image | Screen and reproduction | Finding and verification |
| --- | --- | --- |
| 1 | Sign in as branch admin and open Dashboard | **High**. Missing branch assignment is shown correctly. The supplied admin had no branch in the live profile. Assign only an approved branch and verify scoped access. |
| 2 | Profile → Sign Out | Confirmation renders. Cancellation and session clearing on this device were not tested. |
| 3 | Settings → Privacy Policy | **Release blocker**. Document is unpublished. Owner-approved content must be provided. |
| 4 | Settings → Terms of Service | **Release blocker**. Document is unpublished. Owner-approved content must be provided. |
| 5 | Settings → About & Updates | Shows 1.8.3+20 and update options. USB upgrade evidence exists. In-app download and install remain untested. |
| 6 | Settings → Preferences | Theme, language and notification controls render. Persistent device behavior remains unverified. |
| 7 | Profile → Change Password | Form is visible. Reauthentication, validation and password change remain untested on the phone. |
| 8 | Profile → Help Center | Phone, email and WhatsApp appear. Verify ownership before relying on these contact details. |
| 9 | Profile → Preferences | Change Password description mentions sending a link while the flow opens a change form. Copy corrected on this branch. |
| 10 | Profile → Saved Payment Methods | Wallet reference is masked and clearly labeled. No live gateway payment is implied. |
| 11 | Saved Payment Methods, duplicate view | Same wallet-reference state. Add/edit/delete round trip not verified. |
| 12 | Profile → Delivery addresses | Saved address and add/edit controls render. Round trip and default selection not tested on this build. |
| 13 | Profile → Edit Profile | Profile form and save button render. The blue banner is Android screenshot feedback. Profile save and image upload remain unverified. |
| 14 | Profile overview | Account links and counters render. Their live values remain unverified. |
| 15 | Support chat | Conversation and composer render. Delivery, push and unread transitions require staging. |
| 16 | My Orders → Current | **High**. Cached orders and a load error appear together. Root cause requires the failing live request and deployment context. Local order lifecycle tests cover the backend transitions. |
| 17 | Loyalty Tokens | Balance and history render. The exit prompt appears in the view. Device navigation and live accrual remain unverified. |
| 18 | Search | Long title clips at narrow width. Shortened on this branch. Suggested restaurants and their search behavior remain unverified. |
| 19 | Notifications | Empty state renders. FCM receipt and unread counters need staged delivery. |
| 20 | Cart | Expected empty state. Flutter cart regressions passed. Device persistence remains unverified. |
| 21 | Home → Filter & Sort | Options render. Device filtering and sort behavior remain unverified. |
| 22 | Food Menu | Catalog and customization actions render. Product image mappings need owner-confirmed SKU data. |
| 23 | Home → Recently ordered | Cards render. Verify ordering against the signed-in user's actual history. |
| 24 | Home | Hero, categories and branch appear. Existing responsive tests exercise Home. Live location and catalog sync remain unverified. |
| 25 | Login → submit | **High**. Transport reset was exposed as raw text. Map it to a retry message. The screenshot does not establish the cause of the network reset. |
| 26 | Rider → assigned delivery → Accept | **Critical**. Server action unavailable. The last production listing contained zero Functions. The local transactional acceptance and concurrency tests passed. |
| 27 | Rider → assigned delivery | COD amount and actions render. Verify data with a staged order. |
| 28 | Rider → Profile | Profile renders without the delivery error banner. Targeted Flutter regression passed. |
| 29 | Rider → Earnings | **High**. Earnings unavailable. Staged fetch, displayed earnings and COD receipts need reconciliation. |
| 30 | Rider → Orders | **High**. Delivery error and cached assignments coexist. Live query and index behavior need staging. |
| 31 | Rider → Home | **High**. Offers visible while a delivery read failed. Retry and acceptance must be verified against deployed Functions and rules. |

## Publication gates

The Windows workflow now produces an installer and checksum. The release workflow collects and verifies both platform bundles before publishing a single release. Flutter Doctor found no local Visual Studio compiler. GitHub Actions release credential availability and the full installer lifecycle still need verification. Production checkout and rider callables, approved legal content, and staged phone verification block publication.
