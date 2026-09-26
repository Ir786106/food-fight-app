import 'package:flutter/material.dart';

/// Food Fight brand colors.
/// "Food" side = warm orange/red (appetite, energy)
/// "Fight" side = deep charcoal/black (bold, punchy)
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFFFF3D2E); // Fiery red-orange
  static const Color primaryDark = Color(0xFFD8281B);
  static const Color secondary = Color(0xFF1C1C24); // Fight black
  static const Color accent = Color(0xFFFFC839); // Golden yellow

  // Background colors
  static const Color background = Color(0xFFF7F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F5);

  // Text colors
  static const Color textPrimary = Color(0xFF1C1C24);
  static const Color textSecondary = Color(0xFF7A7A85);
  static const Color textLight = Color(0xFF9A9AA5);

  // Status colors
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);

  // Order status colors
  static const Color orderPending = Color(0xFFF39C12);
  static const Color orderAccepted = Color(0xFF3498DB);
  static const Color orderPreparing = Color(0xFF9B59B6);
  static const Color orderReady = Color(0xFF1ABC9C);
  static const Color orderOutForDelivery = Color(0xFFE67E22);
  static const Color orderDelivered = Color(0xFF2ECC71);
  static const Color orderCancelled = Color(0xFFE74C3C);

  // Role colors
  static const Color customerColor = Color(0xFF3498DB);
  static const Color riderColor = Color(0xFFE67E22);
  static const Color staffColor = Color(0xFF9B59B6);
  static const Color adminColor = Color(0xFF1C1C24);

  // Divider
  static const Color divider = Color(0xFFEAEAEF);
  static const Color dividerDark = Color(0xFFD0D0D5);

  // Overlay
  static Color withAlpha(Color color, double alpha) =>
      color.withValues(alpha: alpha);
}
