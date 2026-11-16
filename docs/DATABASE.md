# Current data contracts

Checkout reads users, branches, deliveryAreas, menuItems or legacy menu_items, deals, addresses, coupons and loyaltyAccounts. Placement writes an inline order snapshot, stock and coupon counts, branch counters, notifications, an audit record and a loyalty ledger entry when applicable. Quotes perform reads only.

Amounts stored or returned at the contract boundary are PKR rupees. The function uses integer paisa for arithmetic. The marketplace ERD requires an explicit migration before moving to nested tenant resources or changing persisted units.

Branch staff with the relevant module permission can mutate categories and menu items owned by their branch. Existing unscoped catalog records remain publicly readable, with writes reserved for super admins. Both branchId and the legacy branch_id representation are recognized. Cross-branch moves require super admin access.

The codCollections document ID matches its order ID. amountPaisa is an integer. Delivery and the COD receipt commit in one transaction. The receipt records cash collected from the customer. Branch staff can record full cash handover with settledAt and settledBy on the receipt. The order mirrors the status in codSettlementStatus. Rider earnings and payout workflows are pending.

## Legacy tenant audit and backfill

The migration scans the root tenant, restaurant and branch collections, user and rider profiles, both catalog naming conventions, orders and linked operational records. The exact collection list lives in `functions/migrate_legacy_tenants.js`. User-owned addresses, payment methods, favorites, loyalty and individual notifications remain account-scoped. Chat messages and tracking records inherit scope through their parent and are not rewritten.

Ownership evidence comes from stored canonical IDs, legacy aliases and existing parent documents. An existing restaurant serves as its own tenant root where there is no separate tenants collection. Conflicting IDs, missing parents, missing profile roles and profile branch assignments require manual review. The migration does not infer privileged roles or grant a profile a branch. Existing nonempty values are preserved. Missing timestamps use legacy timestamp fields or Firestore metadata. Lifecycle status uses an explicit legacy `isActive` flag when present. Other statuses are reported for review.

The JSON report includes document paths, proposed or written fields, issues, counts and collection checkpoints. It reports the environment being scanned. Production data was not inspected from this workspace.
