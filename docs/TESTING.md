# Local verification

From the food_fight repository run:

    flutter pub get --offline
    flutter analyze --no-pub
    flutter test --no-pub
    node --check functions/index.js
    node --test functions/checkout.test.js
    firebase emulators:exec --project demo-food-fight --only firestore "npm --prefix test/rules test"

The Node checkout suite uses an in-memory transaction substitute. Use the Firebase emulator or staging for platform-specific transaction and callable behavior, then run a device checkout from catalog through delivery.

## Latest verified results

- Node checkout suite passed 4 tests.
- Firestore demo emulator suite passed 15 tests.
- Focused Flutter cart, order and workflow suite passed 18 tests.
- The initial full run found uninitialized Flutter bindings in customer cart tests. Test setup was corrected. A complete clean full-suite result remains a release gate.

Run the order lifecycle test against a local demo Firestore emulator from food_fight.

    firebase emulators:exec --project demo-food-fight --only firestore "node --test functions/order_lifecycle.emulator.test.js"

The test exercises the callable handler against Firestore, including transaction concurrency. Firebase Auth tokens, callable transport and device interaction need staging verification.

## Authenticated callable smoke test

From the Flutter project directory with the Functions dependencies installed, run the local demo emulators on their default ports. Use an available custom port and update FOODFIGHT_FUNCTIONS_EMULATOR_HOST if the default Functions port is occupied.

    $env:GCLOUD_PROJECT = 'demo-food-fight'
    $env:FOODFIGHT_FUNCTIONS_EMULATOR_HOST = '127.0.0.1:5001'
    firebase emulators:exec --project demo-food-fight --only auth,functions,firestore "node --test functions/order_lifecycle.emulator.test.js"

Keep provider credentials out of the demo emulator environment. The test creates synthetic customer, kitchen and rider accounts, signs in using the Auth emulator, and sends Firebase callable requests with the resulting ID tokens. It verifies unauthenticated rejection, quote and idempotent checkout, fulfillment, COD settlement, and rejection of a customer settlement request. This is a local transport test. Provider services and device UI require staging.
