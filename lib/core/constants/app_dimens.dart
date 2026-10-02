import 'package:flutter/material.dart';

/// Centralized layout dimensions, radii, elevation, and spacing tokens
/// to maintain strict visual consistency across the Food Fight customer UI.
class AppDimens {
  // Spacing & Margins (8-pt grid system)
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
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius14 = 14.0;
  static const double radius16 = 16.0;
  static const double radius18 = 18.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius28 = 28.0;
  static const double radiusFull = 999.0;

  // Icon & Button Heights
  static const double minTouchTarget = 48.0;
  static const double buttonHeight = 52.0;
  static const double buttonHeightSm = 40.0;

  // Floating Nav Bar Specs
  static const double navBarHeight = 68.0;
  static const double navBarCenterButtonSize = 58.0;
  static const double navBarNotchRadius = 36.0;
  static const double navBarNotchSmoothness = 12.0;
  static const double navBarHorizontalMargin = 18.0;
  static const double navBarBottomMargin = 14.0;
  static const double navBarScrollPadding = 120.0;

  // Product Card Specs
  static const double foodCardRadius = 24.0;
  static const double foodCardImageSize = 100.0;
  static const double foodCardWidth = 168.0;

  // Soft Shadows (Warm neutral & brand aligned)
  static List<BoxShadow> softShadow({Color? color, double opacity = 0.08}) => [
        BoxShadow(
          color: (color ?? const Color(0xFF2A1415)).withValues(alpha: opacity),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> floatingPillShadow({Color? color, double opacity = 0.12}) => [
        BoxShadow(
          color: (color ?? const Color(0xFF2A1415)).withValues(alpha: opacity),
          blurRadius: 22,
          spreadRadius: 2,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> glowShadow({required Color color, double opacity = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 16,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ];
}
