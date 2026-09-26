import 'package:flutter/material.dart';

/// Admin Theme Colors & Styling (Consistent with reference repository patterns)
class AdminTheme {
  static const Color primaryBlue = Color(0xFF0D47A1);
  static const Color secondaryBlue = Color(0xFF1976D2);
  static const Color accentCyan = Color(0xFF00B4D8);
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF111115)
        : background;
  }

  static Color getCardBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A22)
        : cardBg;
  }

  static Color getTextDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF7F7FA)
        : textDark;
  }

  static Color getTextMuted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFA2A2B0)
        : textMuted;
  }

  // Status colors
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusAccepted = Color(0xFF3B82F6);
  static const Color statusPreparing = Color(0xFF8B5CF6);
  static const Color statusReady = Color(0xFF06B6D4);
  static const Color statusOutForDelivery = Color(0xFFEA580C);
  static const Color statusDelivered = Color(0xFF10B981);
  static const Color statusCancelled = Color(0xFFEF4444);

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return statusPending;
      case 'accepted':
        return statusAccepted;
      case 'preparing':
        return statusPreparing;
      case 'ready':
        return statusReady;
      case 'outfordelivery':
      case 'out for delivery':
        return statusOutForDelivery;
      case 'delivered':
        return statusDelivered;
      case 'cancelled':
        return statusCancelled;
      default:
        return textMuted;
    }
  }
}
