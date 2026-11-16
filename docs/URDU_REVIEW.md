# Urdu review

The ARB catalogs contain the translations previously shipped in the app. Run `node tool/localization_catalog.cjs --write` after editing them. CI checks key and placeholder parity and verifies the generated Dart lookup.

Review food, payment, delivery and branch management wording with a native Urdu speaker. In particular, confirm the operational labels for cash settlement, staff suspension, and delivery failure. Test long Urdu text at system text scales 1.0 and 2.0 on Android and Windows. Check chart labels, table column order, directional icons, timelines and phone/email display.

Coverage is incomplete. Legacy text in the four panels and user-facing messages from Cloud Functions still need extraction and translation. A bundled Urdu font and app-wide RTL/golden verification are pending.
