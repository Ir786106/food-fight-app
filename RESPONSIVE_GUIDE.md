# Food Fight — Responsive Architecture & Layout Guide

This guide establishes the responsive engineering standards for all screens, panels, and modal interfaces across the **Food Fight** multi-platform application (Android, iOS, iPadOS, macOS, Windows, and Flutter Web).

---

## 1. Window Size Classes & Breakpoints

Food Fight implements Google's official **Material 3 Window Size Classes**, measured against the screen or parent layout container's width:

| Size Class | Breakpoint Range | Typical Target Devices | Key Layout Paradigm |
| :--- | :--- | :--- | :--- |
| **Compact** | `< 600 dp` | Phones (portrait), narrow foldables | Single column, BottomNavigationBar / Drawer, modal bottom sheets |
| **Medium** | `600 – 839 dp` | Foldables unfolded, small tablets, landscape phones | Collapsed NavigationRail (72dp), multi-column cards, centered dialogs |
| **Expanded** | `840 – 1199 dp` | Large tablets (iPad Pro), laptops, split web | Permanent NavigationRail / Sidebar (260dp), 2-column master-detail |
| **Large** | `≥ 1200 dp` | Desktop monitors, full-screen web browsers | Permanent extended sidebar + max-width centered content (1200dp), full DataTables |

### Phone vs. Tablet Disambiguation

A phone held in landscape mode must **not** be treated as a tablet. We check:

```dart
final isPhone = MediaQuery.sizeOf(context).shortestSide < 600;
```

If `isPhone` is true, the layout uses phone navigation patterns even when horizontal width exceeds 600 dp.

---

## 2. Core Responsive Utilities (`lib/core/responsive/`)

Always import:

```dart
import 'package:food_fight/core/responsive/responsive.dart';
```

### A. Context Extensions (Performant `MediaQuery.sizeOf`)

Never call `MediaQuery.of(context)` inside widget build methods, as any change to system insets or animation will trigger a full widget rebuild. Instead use:

```dart
context.screenWidth      // double (using MediaQuery.sizeOf(context).width)
context.screenHeight     // double (using MediaQuery.sizeOf(context).height)
context.windowClass      // WindowSizeClass (compact, medium, expanded, large)
context.isCompact        // bool (< 600)
context.isMedium         // bool (600 - 839)
context.isExpanded       // bool (840 - 1199)
context.isLarge          // bool (>= 1200)
context.isWide           // bool (>= 840)
context.isPhone          // bool (shortestSide < 600)
context.isTablet         // bool (shortestSide >= 600)
context.gridColumns      // int (auto-computed 2..6 columns)
```

### B. `AdaptiveLayout`

Use `AdaptiveLayout` when top-level structure fundamentally shifts between size classes:

```dart
AdaptiveLayout(
  compact: (context) => const MobileOrderList(),
  medium: (context) => const TabletSplitView(),
  expanded: (context) => const DesktopMasterDetailView(),
)
```

### C. `ResponsiveBox` (Max Content Width Constraint)

To prevent forms, dashboards, and auth cards from awkwardly stretching across ultra-wide monitors (1920px+), wrap content in `ResponsiveBox`:

```dart
// For Authentication (max 480 dp centered)
ResponsiveBox.auth(child: LoginForm())

// For Forms & Checkout (max 600 dp centered)
ResponsiveBox.form(child: CheckoutForm())

// For Admin Dashboards & Grids (max 1200 dp centered)
ResponsiveBox.dashboard(child: MetricsGrid())
```

---

## 3. Screen Construction Patterns

### Rule 1: Responsive Grid Columns

Never hardcode column counts in `GridView`:

```dart
// ✅ RECOMMENDED: Max cross-axis extent scales seamlessly across 320px to 4K displays
GridView.builder(
  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 220,
    mainAxisSpacing: 14,
    crossAxisSpacing: 14,
    childAspectRatio: 0.78,
  ),
  itemCount: items.length,
  itemBuilder: (context, i) => FoodCard(item: items[i]),
)
```

### Rule 2: Ellipsis & Flexible Protection Inside Rows

Any dynamic text or label inside a `Row` **must** be wrapped in `Expanded` or `Flexible` with an explicit overflow strategy:

```dart
// ✅ PREVENTS RenderFlex Overflow at 1.3x and 2.0x system font scale
Row(
  children: [
    const Icon(Icons.location_on),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        branch.address,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
)
```

### Rule 3: Wrap for Categorical Pills & Badges

Avoid placing multiple badges in a single `Row` where high text scaling can push content outside screen boundaries:

```dart
// ✅ WRAPS automatically when badges exceed line width
Wrap(
  spacing: 8,
  runSpacing: 6,
  children: [
    RatingBadge(rating: food.rating),
    TimeBadge(prepTime: food.prepTimeMinutes),
    if (food.isSpicy) const SpicyBadge(),
  ],
)
```

### Rule 4: Adaptive Modals & Dialogs

Display bottom sheets on phones, but centered modal dialogs on tablets/desktops:

```dart
if (context.isCompact) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const OrderDetailModal(),
  );
} else {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: const OrderDetailModal(),
      ),
    ),
  );
}
```

### Rule 5: Keyboard Inset Handling

Always make forms vertically scrollable so the on-screen software keyboard does not cause bottom overflow:

```dart
Scaffold(
  resizeToAvoidBottomInset: true,
  body: SafeArea(
    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(...),
    ),
  ),
)
```

---

## 4. Navigation Architecture by Role

| User Role | Compact (<600) | Medium (600–839) | Expanded & Large (≥840) |
| :--- | :--- | :--- | :--- |
| **Customer** | Floating bottom bar + prominent FAB cart | Vertical NavigationRail | NavigationRail + wide centered content |
| **Admin** | Collapsible drawer + bottom action bar | Collapsed NavigationRail (72px) | Permanent extended sidebar (260px) + top bar |
| **Super Admin** | HQ Drawer + bottom quick tabs | Collapsed NavigationRail (72px) | Permanent extended sidebar (260px) + audit view |
| **Rider** | Full-width single column delivery queue | Side-by-side queue | Left: live GPS route; Right: order cards |

---

## 5. Verification Checklist for New Screens

Before committing any new screen or widget:

- [ ] Tested at **320x568** (iPhone SE) with **2.0x font scale** (zero `RenderFlex` overflow).
- [ ] Tested at **1920x1080** (Desktop Web) with content centered and constrained.
- [ ] Rotated screen 90° between portrait and landscape.
- [ ] Soft keyboard raised without viewport clipping.
- [ ] `flutter analyze` runs with **0 errors and 0 warnings**.
