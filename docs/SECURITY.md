# Security status

Checkout verifies Firebase authentication, checks inactive or blocked profile state and calculates prices from Firestore. Order writes and stock, coupon and loyalty updates use a single transaction. Rules prohibit rider access to unrelated user profiles. The assigned order supplies delivery details. A blocked account cannot clear its own block flag or delete its profile under these rules.

Catalog rules scope category and menu-item writes by branch, including the legacy menu_items collection. Shared entries require super admin access for writes.

Marketplace launch still requires consistent ownership enforcement on other collections, consistent role revocation, server-enforced rider assignments and order transitions, callable App Check and abuse controls, audited privileged actions and signed Supabase uploads. See the audit for current rule gaps.
