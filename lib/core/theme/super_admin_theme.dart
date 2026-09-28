import 'package:flutter/material.dart';
import 'package:food_fight/core/theme/admin_theme.dart';

/// Super Admin Visual Theme - Premium Deep Purple / Gold / Obsidian accents
class SuperAdminTheme {
  static const Color primary = Color(0xFF3C1810); // Food Fight Dark Brown
  static const Color secondary = Color(0xFF2E1A11); // Food Fight Deep Dark Brown
  static const Color accentGold = Color(0xFFFFC700); // Food Fight Yellow
  static const Color accentCyan = Color(0xFFFFC700); // Food Fight Yellow
  static const Color background = Color(0xFFFAF6F0); // Warm Cream Neutral
  static const Color darkBackground = Color(0xFF170F0B); // Deep Roasted Chocolate
  static const Color darkCardBg = Color(0xFF231812); // Dark Chocolate Card
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
