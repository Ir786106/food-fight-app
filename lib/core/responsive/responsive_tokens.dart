import 'package:flutter/material.dart';

/// Design tokens for consistent responsive spacing, radii, and content constraints across all devices.
class ResponsiveTokens {
  // Spacing Scale
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Corner Radii
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;
  static const double radiusFull = 999.0;

  // Maximum Content Widths for wide displays
  static const double authMaxWidth = 480.0;
  static const double formMaxWidth = 600.0;
  static const double checkoutMaxWidth = 720.0;
  static const double modalMaxWidth = 640.0;
  static const double contentMaxWidth = 1200.0;
  static const double dashboardMaxWidth = 1440.0;

  // Standard Minimum Tap Target (WCAG 2.1 AA / Material requirement)
  static const double minTapTarget = 48.0;

  // Responsive padding getter
  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    } else if (width < 840) {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0);
    }
  }
}
