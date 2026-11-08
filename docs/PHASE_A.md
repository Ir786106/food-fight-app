# Phase A - global foundations

Status: implementation in progress; final validation pending.

## Changes

| Files | Change | Reason |
| --- | --- | --- |
| `lib/core/utils/app_insets.dart`, `lib/core/constants/app_dimens.dart` | Single navigation height and explicit visible-overlay clearance; cart-only overlay supported | Prevent fixed bottom bands and mismatched reserved space |
| `lib/core/utils/app_snackbar.dart`, `lib/core/constants/app_colors.dart` | Shared feedback colors, spacing, icons, timing and actions | Consistent readable feedback above Scaffold-owned bars |
| `lib/theme/app_theme.dart` | Shared centered app-bar defaults and minimum button/icon-button targets | Consistent navigation and accessibility |
| `lib/screens/home/main_navigation_screen.dart`, `lib/screens/chat/customer_chat_screen.dart` | Chat back arrow delegates to existing shell | Prevent recursively mounting Home and a second navigation bar |
| Cart, favorites, order history, order success | Home reset actions target root navigator | Prevent Home shells inside tab navigators |
| `lib/screens/checkout/order_success_screen.dart` | Visible Home back arrow and system-back reset even with missing order data | Never return to checkout after success |
| Food detail, cart, checkout, edit profile | Bottom action bars exclude the top status-bar inset | Remove accidental extra vertical padding above sticky actions |
| `lib/widgets/navigation/floating_nav_bar.dart` | Divider paints inside canonical height | Keep measured bar height equal to inset calculations |
| `test/global_layout_feedback_test.dart` | Insets, feedback placement, hidden bar, and success-back regression checks; rendered PNG evidence | Verify layout and back behavior |

Previous work in this branch also replaced fake default ratings with real-count gating, added actual dish sharing, moved help contacts into settings, removed fabricated nutrition, and migrated raw snackbar calls to the common helper. These remain part of the global acceptance check.

## Manual acceptance checklist

Repeat at 360x640, 411x891 and tablet widths >=840; light/dark; text scale 1.0 and 1.3; gesture and three-button Android navigation.

- [ ] Exactly one customer navigation bar, or a tablet rail; no gap when hidden.
- [ ] Home -> Chat -> app-bar Back returns to previous tab; no nested Home shell.
- [ ] System Back dismisses keyboard, then modal/drawer, then current nested route, then previous tab/Home.
- [ ] Root checkout, tracking, search, notifications, settings and profile-edit routes pop normally.
- [ ] Order success Back and Continue Shopping clear checkout and return Home.
- [ ] Admin/super-admin section Back returns to dashboard; dashboard exit follows the existing confirmation flow.
- [ ] Rider Back handles keyboard before exit confirmation.
- [ ] Add/Save/Checkout action bars use system bottom inset once.
- [ ] Feedback appears above navigation/action bars with readable icon, text and action.
- [ ] Zero-review cards/details show New or no rating, never an invented average.
- [ ] Missing photos show a neutral fallback; each menu item uses its own stored image.
- [ ] Share Dish opens the platform share sheet.
- [ ] Help hides missing contact fields; configured phone/email/WhatsApp opens the appropriate application.
- [ ] Sheets/dialogs/fields remain readable in dark mode and at large text scale.

Automated test results and screenshot paths will be recorded after the pending runs finish. Device-only behavior (Android back gestures, real share sheet, external contact apps) requires an emulator/device check.
