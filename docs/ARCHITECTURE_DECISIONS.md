# Architecture decisions

- Keep the existing Flutter entry point and Firebase project mapping while the marketplace evolves. The three apps, shared package, Riverpod, GoRouter and TypeScript remain target architecture. Extract incrementally so working role flows remain available.
- Existing Firestore records store PKR in rupees. Use integer paisa inside checkout calculations and convert at the existing API and storage boundary. A persistent field migration requires a staged backfill.
- Keep branch identifiers, top-level menus and addresses, and inline order items in the current checkout contract. Map to the ERD restaurant ownership and nested schemas through a tested migration before treating the legacy scope as a marketplace tenant boundary.
- Use one pricing routine for quote and commit. Keep the placement idempotency contract and revalidate at commit time. Offer only COD at checkout until a provider is verified.
- The master prompt resolves the PRD open question in favor of a multi-restaurant marketplace and specifies manual and nearest-available rider assignment. Adaptive location cadence supersedes the reference API's fixed interval.
- Prefer server-authorized, scoped Supabase uploads. The legacy direct upload path requires a coordinated application and bucket-policy migration.
