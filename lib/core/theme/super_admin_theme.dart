import 'package:flutter/material.dart';
import 'package:food_fight/core/theme/admin_theme.dart';

/// Super Admin Visual Theme - Premium Deep Purple / Gold / Obsidian accents
class SuperAdminTheme {
  static const Color primary = Color(0xFF3F1651); // Imperial Purple
  static const Color secondary = Color(0xFF5B1B74);
  static const Color accentGold = Color(0xFFFFB703); // Golden crest
  static const Color accentCyan = Color(0xFF00C49F);
  static const Color background = Color(0xFFF9F7FA);
  static const Color darkBackground = Color(0xFF0F0B13);
  static const Color darkCardBg = Color(0xFF191220);
  static const Color cardBg = Colors.white;

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
