# Staging verification

1. Create a Firebase staging project and configure the matching Flutter registrations, Auth, FCM, App Check, Maps and Supabase image bucket. Check the project ID in each built app. Use separate test identities for customer, rider, branch A staff, branch B staff and Super Admin. See [environment setup](ENVIRONMENT_SETUP.md).
2. Deploy to staging only using `firebase deploy --project STAGING_ID --only firestore:rules,firestore:indexes,functions`. Wait for the indexes to become ready. Verify branch/order history and rider status/earnings queries against `firestore.indexes.json`. Metrics use document reads and an unrestricted Super Admin collection listener, so they add no composite index.
3. Export the default Firestore database and retain the completed export operation receipt. Follow [deployment and rollback](DEPLOYMENT.md#backfill-legacy-tenant-metadata).
4. Run the tenant backfill in dry-run mode and review orphan and role entries. Confirm that the dry run writes no Firestore data.
5. Apply the additive migration in staging with the export receipt. Run a new dry run and review any remaining unresolved entries. Copy legacy financial totals using the separate copy tool.
6. Run `node functions/verify_branch_metrics.js --project=STAGING_ID` and review every row. A stale public total is a mismatch to investigate. Use `--require-clean` only when checking an environment where the separately authorized cleanup has occurred.
7. Run the access and functional checks below. If any check fails, stop the rollout and use the documented export and field-level rollback procedure.

## Access checks

Run the Firestore rules suite against the emulator before staging. In staging, check the same document paths with client SDK sessions because the verification script uses Admin credentials and bypasses rules.

Use a fresh emulator instance for each integration suite. The platform suite checks global totals, so order-lifecycle fixtures from another suite change its expected counts.

    firebase emulators:exec --project demo-food-fight --config firebase.demo.json --only auth,firestore "node --test functions/order_lifecycle.emulator.test.js"
    firebase emulators:exec --project demo-food-fight --config firebase.demo.json --only auth,firestore "node --test functions/platform_administration.emulator.test.js"

| Identity | Expected result |
| --- | --- |
| Customer, rider or guest | Private document reads and collection queries denied |
| Branch A staff with reports permission | Branch A document allowed, branch B and unrestricted list denied |
| Super Admin | Both branches and the collection readable |
| Public branch profile | Public metadata readable. Financial fields absent after authorized cleanup |

## Functional smoke tests

1. Super Admin records both branches' starting private order counts and revenue.
2. Customer places a COD order in branch A. Admin opens and assigns it. Rider accepts, picks up, delivers and records cash. Admin confirms COD settlement.
3. Super Admin confirms branch A order count rose by one and revenue rose by the order total. Branch B is unchanged. Reopen the dashboard to check persisted values.
4. Place a second order and cancel it before delivery. Confirm the new order increased the placement count, cancellation reversed that order's revenue, and retrying the cancellation does not repeat the reversal. Verify the customer and admin see the terminal status.

## Cost impact

Placement and server-verified cancellation each add one private metrics read and move the existing financial write to the private document. Customer quotes and branch browsing gain no metrics read. The Super Admin branch views add one private metrics document read per branch on their initial collection snapshot and billed reads for subsequent updates. The parity verifier reads a public branch and its private counterpart per branch. The backfill scans each configured collection, reads ownership references where present, and adds transactional re-reads and one write per eligible document in apply mode. Retries may add reads.
