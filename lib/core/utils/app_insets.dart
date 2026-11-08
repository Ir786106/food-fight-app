import 'package:flutter/material.dart';
import '../constants/app_dimens.dart';

/// Centralized insets and clearance calculator for the Food Fight application.
/// Ensures that no screen suffers from blank bands or overlapped action bars
/// across both 3-button and gesture Android navigation modes, as well as iOS home indicators.
class AppInsets {
  AppInsets._();

  /// Canonical height of the flat customer bottom navigation bar.
  static const double navBarHeight = AppDimens.navBarHeight;

  /// Canonical height of the floating cart mini-pill.
  static const double cartPillHeight = AppDimens.cartPillHeight;

  /// Canonical height of a standard sticky bottom action bar (e.g. Add to Cart, Checkout).
  static const double bottomActionBarHeight = AppDimens.bottomActionBarHeight;

  /// Returns system bottom padding (gesture bar or 3-button nav inset).
  static double safeBottom(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom;
  }

  /// Scroll bodies inside a Scaffold already exclude bottomNavigationBar.
  /// Set [hasNav] only for an overlay, never for a Scaffold-owned bar.
  static EdgeInsets scrollPadding(
    BuildContext context, {
    double horizontal = AppDimens.space16,
    double top = AppDimens.space16,
    bool hasNav = false,
    bool hasCartPill = false,
  }) =>
      EdgeInsets.fromLTRB(
          horizontal,
          top,
          horizontal,
          bottomBarClearance(context,
              hasNav: hasNav, hasCartPill: hasCartPill));

  /// Calculates the exact scroll clearance required at the bottom of scrollable views
  /// (ListView, SingleChildScrollView, CustomScrollView).
  ///
  /// - If [hasNav] is true, accounts for the bottom navigation bar and its safe area.
  /// - If [hasCartPill] is true, accounts for the floating cart mini-pill sitting above the nav.
  /// - [additional] allows fine-grained spacing per screen requirement.
  static double bottomBarClearance(
    BuildContext context, {
    bool hasNav = false,
    bool hasCartPill = false,
    double additional = 0.0,
  }) {
    final bottomPadding = safeBottom(context);
    return bottomPadding +
        AppDimens.space16 +
        additional +
        (hasNav ? navBarHeight : 0) +
        (hasCartPill ? cartPillHeight + AppDimens.space12 : 0);
  }

  /// Inset for bottom action bars (Add to Cart, Proceed to Checkout, Place Order, Save Profile).
  /// Sits flush on the screen bottom with system safe area respected.
  static EdgeInsets bottomActionBarPadding(
    BuildContext context, {
    double horizontal = AppDimens.space16,
    double top = AppDimens.space12,
    double bottom = AppDimens.space12,
  }) {
    return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      bottom + safeBottom(context),
    );
  }

  /// Returns the bottom offset for floating components (such as floating cart mini-pill).
  static double floatingCartOffset(
    BuildContext context, {
    bool hasNav = true,
  }) {
    final bottomPadding = safeBottom(context);
    if (hasNav) {
      return navBarHeight + bottomPadding + AppDimens.space12;
    }
    return bottomPadding + AppDimens.space16;
  }
}
