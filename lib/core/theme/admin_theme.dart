import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Admin Theme Colors & Styling (Consumes AppColors single source of truth)
class AdminTheme {
  static const Color primaryBlue = AppColors.brandMaroon;
  static const Color secondaryBlue = AppColors.maroonDeep;
  static const Color accentCyan = AppColors.brandYellow;
  static const Color background = AppColors.background;
  static const Color cardBg = AppColors.surface;
  static const Color textDark = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;

  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBackground
        : background;
  }

  static Color getCardBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurface
        : cardBg;
  }

  static Color getTextDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : textDark;
  }

  static Color getTextMuted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : textMuted;
  }

  // Status colors mapped to AppColors
  static const Color statusPending = AppColors.statusPending;
  static const Color statusAccepted = AppColors.statusAccepted;
  static const Color statusPreparing = AppColors.statusPreparing;
  static const Color statusReady = AppColors.statusReady;
  static const Color statusOutForDelivery = AppColors.statusOutForDelivery;
  static const Color statusDelivered = AppColors.statusDelivered;
  static const Color statusCancelled = AppColors.statusCancelled;

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
