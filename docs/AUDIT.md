# Food Fight marketplace audit

The Git repository is in `food_fight/`. The outer workspace holds project tooling and historical APKs. The app is a single Flutter project with customer, rider, restaurant admin, sub-admin and super admin routes, Provider state, Firebase bootstrap, platform projects, assets, JavaScript Functions, Firestore rules and indexes, and Flutter and rules tests. The starting tree already contained extensive staged, unstaged and untracked work.

| Source | Coverage |
| --- | --- |
| PRD | One-city COD launch, personas, journeys, MVP priorities and open business decisions |
| SRS | Functional requirements by role, order state machine and security and operational requirements |
| SAD | Three Flutter apps, shared package, Firebase, Riverpod, GoRouter and signed Supabase storage |
| ERD | Marketplace ownership, tenant-scoped collections, order snapshots, dispatch, ledgers and indexes |
| API | Callable contracts, data and errors, push events and upload authorization |
| UI/UX | Screen inventory, responsive design, provisional tokens, accessibility and Urdu RTL |

Reuse the existing screens, models, navigation, Firebase and Supabase configuration, transaction-based order pricing and idempotency, real-time order listeners, location widgets and tests. Production-shaped differences include branch-oriented collections, top-level addresses and menus, inline order snapshots, Provider and named routes, and JavaScript callables. An installed Flutter 3.47.2 and Dart 3.13.2 toolchain is present with Firebase CLI 15.29.0, Node 26.5.0, npm 11.17.0 and Java 21. Functions currently declare Node 20. Installed tools alone establish no build compatibility.

Priority findings include global menu mutation permissions for some branch staff, broad user reads by riders, mixed claims and profile authorization, client order-state and rider assignment mutations, missing phone OTP, the starting checkout lacked a server quote, selectable wallet references without gateway settlement, and direct Supabase client uploads. Existing functions, rules and client data need to change together to address these safely. See the requirements matrix for the remaining delivery gaps.

External setup includes a Firebase staging project with Auth phone settings and app fingerprints, App Check registrations, FCM and APNs credentials, restricted Maps keys, Supabase server secrets and bucket policies, and the chosen city, delivery zones, fee and commission policies. iOS release needs macOS and Apple signing access. Any marketplace backfill requires an approved migration and recovery plan.
