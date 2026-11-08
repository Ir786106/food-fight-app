# Current data contracts

Checkout reads users, branches, deliveryAreas, menuItems or legacy menu_items, deals, addresses, coupons and loyaltyAccounts. Placement writes an inline order snapshot, stock and coupon counts, branch counters, notifications, an audit record and a loyalty ledger entry when applicable. Quotes perform reads only.

Amounts stored or returned at the contract boundary are PKR rupees. The function uses integer paisa for arithmetic. The marketplace ERD requires an explicit migration before moving to nested tenant resources or changing persisted units.

Branch staff with the relevant module permission can mutate categories and menu items owned by their branch. Existing unscoped catalog records remain publicly readable, with writes reserved for super admins. Both branchId and the legacy branch_id representation are recognized. Cross-branch moves require super admin access.

The codCollections document ID matches its order ID. amountPaisa is an integer. Delivery and the COD receipt commit in one transaction. The receipt records cash collected from the customer. Branch staff can record full cash handover with settledAt and settledBy on the receipt. The order mirrors the status in codSettlementStatus. Rider earnings and payout workflows are pending.
