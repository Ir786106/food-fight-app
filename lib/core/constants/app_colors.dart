import 'package:flutter/material.dart';

/// Unified Food Fight brand color scheme.
/// Primary: Food Fight Yellow
/// Secondary / Dark: Dark Brown / Chocolate
/// Surfaces: White & Cream Warm Neutral
/// Text: Dark Neutral / Black
class AppColors {
  // Food Fight Unified Palette
  static const Color primaryYellow = Color(0xFFFFC700);
  static const Color darkBrown = Color(0xFF3C1810);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFFAF6F0);
  static const Color lightCream = Color(0xFFF3ECE4);
  static const Color textPrimary = Color(0xFF2E1A11);
  static const Color textSecondary = Color(0xFF7C6961);
  static const Color textMuted = Color(0xFFA09088);
  static const Color border = Color(0xFFE8DFD8);
  static const Color divider = Color(0xFFE8DFD8);
  static const Color dividerDark = Color(0xFF382921);

  // Primary & secondary aliases
  static const Color primary = primaryYellow;
  static const Color primaryDark = Color(0xFFE5B000);
  static const Color primaryLight = Color(0xFFFFD54F);
  static const Color secondary = darkBrown;
  static const Color accent = Color(0xFF4A1A12);

  // Background & surfaces
  static const Color background = cream;
  static const Color surface = white;
  static const Color surfaceVariant = lightCream;
  static const Color textLight = textMuted;

  // Dark mode tokens
  static const Color darkBackground = Color(0xFF170F0B);
  static const Color darkSurface = Color(0xFF231812);
  static const Color darkSurfaceElevated = Color(0xFF2E2018);
  static const Color darkTextPrimary = Color(0xFFFAF6F0);
  static const Color darkTextSecondary = Color(0xFFA6968E);

  // Status colors (semantic only)
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3C1810);

  // Order status colors
  static const Color orderPending = Color(0xFFF39C12);
  static const Color orderAccepted = Color(0xFF3C1810);
  static const Color orderPreparing = Color(0xFF4A1A12);
  static const Color orderReady = Color(0xFFFFC700);
  static const Color orderOutForDelivery = Color(0xFFE5B000);
  static const Color orderDelivered = Color(0xFF2ECC71);
  static const Color orderCancelled = Color(0xFFE74C3C);

  // Role tokens - unified to Food Fight brand
  static const Color customerColor = primaryYellow;
  static const Color riderColor = primaryYellow;
  static const Color staffColor = darkBrown;
  static const Color adminColor = darkBrown;

  // Overlay helper
  static Color withAlpha(Color color, double alpha) =>
      color.withValues(alpha: alpha);
}
