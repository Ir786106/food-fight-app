import 'package:flutter/material.dart';

// Re-export core tokens & themes
export '../constants/app_colors.dart';
export '../constants/app_dimens.dart';
export '../../theme/app_theme.dart';
export 'admin_theme.dart';
export 'super_admin_theme.dart';

// Re-export common design system components
export '../../widgets/custom_button.dart';
export '../../widgets/common/empty_state_view.dart';
export '../../widgets/common/error_view.dart';
export '../../widgets/common/loading_indicator.dart';
export '../../widgets/common/network_image_view.dart';

/// Food Fight Canonical Design System Tokens & Utility Helpers
/// Provides unified access to typography, spacing, radius, elevations,
/// and micro-motion curves across Customer, Admin, and Super Admin modules.
class DesignSystem {
  DesignSystem._();

  // Spacing Scale (4, 8, 12, 16, 24, 32, 48)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Corner Radii
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius28 = 28.0;
  static const double radiusRound = 999.0;

  // Touch Target Minimum (Accessibility standard WCAG 2.1)
  static const double minTouchTarget = 48.0;

  // Animation Curves & Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  static const Curve curveEnter = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
  static const Curve curveEmphasis = Curves.easeInOutCubic;

  // Component Paddings
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets dialogPadding = EdgeInsets.all(24.0);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0);

  // Nav Inset Constant (Reserved bottom scroll padding when floating nav is present)
  static const double floatingNavContentInset = 110.0;
}
