import 'package:flutter/material.dart';

/// Single source of truth for Food Fight design system tokens.
/// Sampled from the authentic brand logo:
/// - Brand Yellow: #FFD505
/// - Brand Maroon: #6D2123
/// - Mustard Accent: #CC9419
/// - Orange Accent: #D06419
class AppColors {
  // ==========================================
  // 1. BRAND COLORS (Light Theme)
  // ==========================================
  static const Color brandYellow = Color(0xFFFFD505);
  static const Color yellowPressed = Color(0xFFE6BF00);
  static const Color yellowSoft = Color(0xFFFFF3B8);
  static const Color yellowTint = Color(0xFFFFFAE0);
  static const Color brandMaroon = Color(0xFF6D2123);
  static const Color maroonDeep = Color(0xFF4A1517);
  static const Color maroonSoft = Color(0xFFF7ECEB);

  // ==========================================
  // 2. NEUTRALS (Warm, professional; NOT yellow-cream)
  // ==========================================
  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF3EEE6);
  static const Color border = Color(0xFFE7DFD3);
  static const Color divider = Color(0xFFEFE8DC);
  static const Color textPrimary = Color(0xFF2A1415);
  static const Color textSecondary = Color(0xFF6B5B58);
  static const Color textMuted = Color(0xFF8F807C);
  static const Color scrim = Color(0x7A2A1415); // 48% opacity of #2A1415

  // ==========================================
  // 3. ACCENTS (From logo illustration)
  // ==========================================
  static const Color tomato = Color(0xFFD9482B);
  static const Color mustard = Color(0xFFCC9419);
  static const Color lettuce = Color(0xFF4C8C2B);
  static const Color illustrationOrange = Color(0xFFD06419);

  // ==========================================
  // 4. SEMANTIC (Functional only, never decorative)
  // ==========================================
  static const Color success = Color(0xFF2E7D32);
  static const Color successSoft = Color(0xFFE6F4E7);
  static const Color warning = Color(0xFFB26A00);
  static const Color warningSoft = Color(0xFFFFF3DC);
  static const Color error = Color(0xFFC62828);
  static const Color errorSoft = Color(0xFFFDECEA);
  static const Color info = Color(0xFF1F5FA8);
  static const Color infoSoft = Color(0xFFE8F0FA);

  // ==========================================
  // 5. ORDER STATUS COLORS
  // ==========================================
  static const Color statusPending = Color(0xFFB26A00);
  static const Color statusPendingSoft = Color(0xFFFFF3DC);
  static const Color statusAccepted = Color(0xFF1F5FA8);
  static const Color statusAcceptedSoft = Color(0xFFE8F0FA);
  static const Color statusPreparing = Color(0xFFE8790F);
  static const Color statusPreparingSoft = Color(0xFFFDF1E6);
  static const Color statusReady = Color(0xFF00796B);
  static const Color statusReadySoft = Color(0xFFE0F2F1);
  static const Color statusAssigned = Color(0xFF4E5BA6);
  static const Color statusAssignedSoft = Color(0xFFEEF0F9);
  static const Color statusPickedUp = Color(0xFF6D2123);
  static const Color statusPickedUpSoft = Color(0xFFF7ECEB);
  static const Color statusOutForDelivery = Color(0xFF6D2123);
  static const Color statusOutForDeliverySoft = Color(0xFFF7ECEB);
  static const Color statusDelivered = Color(0xFF2E7D32);
  static const Color statusDeliveredSoft = Color(0xFFE6F4E7);
  static const Color statusCancelled = Color(0xFFC62828);
  static const Color statusCancelledSoft = Color(0xFFFDECEA);

  // ==========================================
  // 6. DARK THEME TOKENS
  // ==========================================
  static const Color darkBackground = Color(0xFF140C0B);
  static const Color darkSurface = Color(0xFF1E1211);
  static const Color darkSurfaceElevated = Color(0xFF2A1A18);
  static const Color darkBorder = Color(0xFF3A2725);
  static const Color darkDivider = Color(0xFF2F1E1C);
  static const Color darkTextPrimary = Color(0xFFF7EFE6);
  static const Color darkTextSecondary = Color(0xFFBCA9A3);
  static const Color darkTextMuted = Color(0xFF8F7C77);

  static const Color darkSuccess = Color(0xFF66BB6A);
  static const Color darkSuccessSoft = Color(0xFF1E3320);
  static const Color darkWarning = Color(0xFFFFB74D);
  static const Color darkWarningSoft = Color(0xFF3D2C15);
  static const Color darkError = Color(0xFFEF5350);
  static const Color darkErrorSoft = Color(0xFF3B1C1A);
  static const Color darkInfo = Color(0xFF64B5F6);
  static const Color darkInfoSoft = Color(0xFF152A3D);

  // ==========================================
  // 7. BACKWARD COMPATIBILITY & SYSTEM ALIASES
  // (Preserves existing panel & test compatibility)
  // ==========================================
  static const Color brandBrown = brandMaroon;
  static const Color ketchupRed = tomato;
  static const Color freshGreen = lettuce;
  static const Color cheeseOrange = illustrationOrange;
  static const Color primaryYellow = brandYellow;
  static const Color darkBrown = brandMaroon;
  static const Color primary = brandYellow;
  static const Color primaryDark = yellowPressed;
  static const Color primaryLight = yellowSoft;
  static const Color secondary = brandMaroon;
  static const Color accent = maroonDeep;

  static const Color white = surface;
  static const Color cream = background;
  static const Color lightCream = surfaceMuted;
  static const Color surfaceVariant = surfaceMuted;
  static const Color textLight = textMuted;
  static const Color dividerDark = darkDivider;

  static const Color orderPending = statusPending;
  static const Color orderAccepted = statusAccepted;
  static const Color orderPreparing = statusPreparing;
  static const Color orderReady = statusReady;
  static const Color orderOutForDelivery = statusOutForDelivery;
  static const Color orderDelivered = statusDelivered;
  static const Color orderCancelled = statusCancelled;

  static const Color customerColor = brandYellow;
  static const Color riderColor = brandYellow;
  static const Color staffColor = brandMaroon;
  static const Color adminColor = brandMaroon;
  static const Color onYellow = maroonDeep;
  static const Color onYellowDark = maroonDeep;
  static const Color amberDark = Color(0xFF8A5A00);
  static const Color darkAmberDark = brandYellow;
  static const Color darkYellowSoft = Color(0xFF332B10);
  static const Color ctaDark = Color(0xFF2A1415);
  static const Color cardDark = darkSurface;

  static Color withAlpha(Color color, double alpha) =>
      color.withValues(alpha: alpha);
}

/// Helper model encapsulating status styling (icon, colors, label)
class StatusColorInfo {
  final Color color;
  final Color softColor;
  final IconData icon;
  final String label;

  const StatusColorInfo({
    required this.color,
    required this.softColor,
    required this.icon,
    required this.label,
  });
}

/// ThemeExtension to expose order status colors dynamically for Light/Dark themes
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  final Color pending;
  final Color pendingSoft;
  final Color accepted;
  final Color acceptedSoft;
  final Color preparing;
  final Color preparingSoft;
  final Color ready;
  final Color readySoft;
  final Color assigned;
  final Color assignedSoft;
  final Color pickedUp;
  final Color pickedUpSoft;
  final Color outForDelivery;
  final Color outForDeliverySoft;
  final Color delivered;
  final Color deliveredSoft;
  final Color cancelled;
  final Color cancelledSoft;

  const AppStatusColors({
    required this.pending,
    required this.pendingSoft,
    required this.accepted,
    required this.acceptedSoft,
    required this.preparing,
    required this.preparingSoft,
    required this.ready,
    required this.readySoft,
    required this.assigned,
    required this.assignedSoft,
    required this.pickedUp,
    required this.pickedUpSoft,
    required this.outForDelivery,
    required this.outForDeliverySoft,
    required this.delivered,
    required this.deliveredSoft,
    required this.cancelled,
    required this.cancelledSoft,
  });

  static const light = AppStatusColors(
    pending: AppColors.statusPending,
    pendingSoft: AppColors.statusPendingSoft,
    accepted: AppColors.statusAccepted,
    acceptedSoft: AppColors.statusAcceptedSoft,
    preparing: AppColors.statusPreparing,
    preparingSoft: AppColors.statusPreparingSoft,
    ready: AppColors.statusReady,
    readySoft: AppColors.statusReadySoft,
    assigned: AppColors.statusAssigned,
    assignedSoft: AppColors.statusAssignedSoft,
    pickedUp: AppColors.statusPickedUp,
    pickedUpSoft: AppColors.statusPickedUpSoft,
    outForDelivery: AppColors.statusOutForDelivery,
    outForDeliverySoft: AppColors.statusOutForDeliverySoft,
    delivered: AppColors.statusDelivered,
    deliveredSoft: AppColors.statusDeliveredSoft,
    cancelled: AppColors.statusCancelled,
    cancelledSoft: AppColors.statusCancelledSoft,
  );

  static const dark = AppStatusColors(
    pending: Color(0xFFFFB74D),
    pendingSoft: Color(0xFF382811),
    accepted: Color(0xFF64B5F6),
    acceptedSoft: Color(0xFF13283E),
    preparing: Color(0xFFFF9E43),
    preparingSoft: Color(0xFF381F0E),
    ready: Color(0xFF4DB6AC),
    readySoft: Color(0xFF103330),
    assigned: Color(0xFF7986CB),
    assignedSoft: Color(0xFF1F2544),
    pickedUp: Color(0xFFFFD505),
    pickedUpSoft: Color(0xFF382F08),
    outForDelivery: Color(0xFFFFD505),
    outForDeliverySoft: Color(0xFF382F08),
    delivered: Color(0xFF66BB6A),
    deliveredSoft: Color(0xFF18331A),
    cancelled: Color(0xFFEF5350),
    cancelledSoft: Color(0xFF381918),
  );

  static AppStatusColors of(BuildContext context) {
    return Theme.of(context).extension<AppStatusColors>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  StatusColorInfo forStatus(dynamic status) {
    final raw = status is Enum ? status.name : (status?.toString() ?? '');
    final s = raw.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();
    switch (s) {
      case 'pending':
        return StatusColorInfo(
          color: pending,
          softColor: pendingSoft,
          icon: Icons.access_time_rounded,
          label: 'Pending',
        );
      case 'accepted':
        return StatusColorInfo(
          color: accepted,
          softColor: acceptedSoft,
          icon: Icons.check_circle_outline_rounded,
          label: 'Accepted',
        );
      case 'preparing':
        return StatusColorInfo(
          color: preparing,
          softColor: preparingSoft,
          icon: Icons.soup_kitchen_rounded,
          label: 'Preparing',
        );
      case 'ready':
        return StatusColorInfo(
          color: ready,
          softColor: readySoft,
          icon: Icons.inventory_2_outlined,
          label: 'Ready',
        );
      case 'assigned':
        return StatusColorInfo(
          color: assigned,
          softColor: assignedSoft,
          icon: Icons.person_pin_rounded,
          label: 'Assigned',
        );
      case 'pickedup':
      case 'picked up':
        return StatusColorInfo(
          color: pickedUp,
          softColor: pickedUpSoft,
          icon: Icons.takeout_dining_rounded,
          label: 'Picked Up',
        );
      case 'outfordelivery':
      case 'out for delivery':
        return StatusColorInfo(
          color: outForDelivery,
          softColor: outForDeliverySoft,
          icon: Icons.delivery_dining_rounded,
          label: 'Out for Delivery',
        );
      case 'delivered':
        return StatusColorInfo(
          color: delivered,
          softColor: deliveredSoft,
          icon: Icons.check_circle_rounded,
          label: 'Delivered',
        );
      case 'cancelled':
        return StatusColorInfo(
          color: cancelled,
          softColor: cancelledSoft,
          icon: Icons.cancel_rounded,
          label: 'Cancelled',
        );
      default:
        return StatusColorInfo(
          color: AppColors.textMuted,
          softColor: AppColors.surfaceMuted,
          icon: Icons.info_outline_rounded,
          label: status,
        );
    }
  }

  @override
  AppStatusColors copyWith({
    Color? pending,
    Color? pendingSoft,
    Color? accepted,
    Color? acceptedSoft,
    Color? preparing,
    Color? preparingSoft,
    Color? ready,
    Color? readySoft,
    Color? assigned,
    Color? assignedSoft,
    Color? pickedUp,
    Color? pickedUpSoft,
    Color? outForDelivery,
    Color? outForDeliverySoft,
    Color? delivered,
    Color? deliveredSoft,
    Color? cancelled,
    Color? cancelledSoft,
  }) {
    return AppStatusColors(
      pending: pending ?? this.pending,
      pendingSoft: pendingSoft ?? this.pendingSoft,
      accepted: accepted ?? this.accepted,
      acceptedSoft: acceptedSoft ?? this.acceptedSoft,
      preparing: preparing ?? this.preparing,
      preparingSoft: preparingSoft ?? this.preparingSoft,
      ready: ready ?? this.ready,
      readySoft: readySoft ?? this.readySoft,
      assigned: assigned ?? this.assigned,
      assignedSoft: assignedSoft ?? this.assignedSoft,
      pickedUp: pickedUp ?? this.pickedUp,
      pickedUpSoft: pickedUpSoft ?? this.pickedUpSoft,
      outForDelivery: outForDelivery ?? this.outForDelivery,
      outForDeliverySoft: outForDeliverySoft ?? this.outForDeliverySoft,
      delivered: delivered ?? this.delivered,
      deliveredSoft: deliveredSoft ?? this.deliveredSoft,
      cancelled: cancelled ?? this.cancelled,
      cancelledSoft: cancelledSoft ?? this.cancelledSoft,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      pending: Color.lerp(pending, other.pending, t)!,
      pendingSoft: Color.lerp(pendingSoft, other.pendingSoft, t)!,
      accepted: Color.lerp(accepted, other.accepted, t)!,
      acceptedSoft: Color.lerp(acceptedSoft, other.acceptedSoft, t)!,
      preparing: Color.lerp(preparing, other.preparing, t)!,
      preparingSoft: Color.lerp(preparingSoft, other.preparingSoft, t)!,
      ready: Color.lerp(ready, other.ready, t)!,
      readySoft: Color.lerp(readySoft, other.readySoft, t)!,
      assigned: Color.lerp(assigned, other.assigned, t)!,
      assignedSoft: Color.lerp(assignedSoft, other.assignedSoft, t)!,
      pickedUp: Color.lerp(pickedUp, other.pickedUp, t)!,
      pickedUpSoft: Color.lerp(pickedUpSoft, other.pickedUpSoft, t)!,
      outForDelivery: Color.lerp(outForDelivery, other.outForDelivery, t)!,
      outForDeliverySoft: Color.lerp(outForDeliverySoft, other.outForDeliverySoft, t)!,
      delivered: Color.lerp(delivered, other.delivered, t)!,
      deliveredSoft: Color.lerp(deliveredSoft, other.deliveredSoft, t)!,
      cancelled: Color.lerp(cancelled, other.cancelled, t)!,
      cancelledSoft: Color.lerp(cancelledSoft, other.cancelledSoft, t)!,
    );
  }
}
