import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'admin_theme.dart';

/// Super Admin Visual Theme - Consumes AppColors single source of truth
class SuperAdminTheme {
  static const Color primary = AppColors.brandMaroon;
  static const Color secondary = AppColors.maroonDeep;
  static const Color accentGold = AppColors.brandYellow;
  static const Color accentCyan = AppColors.brandYellow;
  static const Color background = AppColors.background;
  static const Color darkBackground = AppColors.darkBackground;
  static const Color darkCardBg = AppColors.darkSurface;
  static const Color cardBg = AppColors.surface;

  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : background;
  }

  static Color getCardBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardBg
        : cardBg;
  }

  static Color getTextDark(BuildContext context) {
    return AdminTheme.getTextDark(context);
  }

  static Color getTextMuted(BuildContext context) {
    return AdminTheme.getTextMuted(context);
  }
}
