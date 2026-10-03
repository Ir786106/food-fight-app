import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';

enum CustomButtonVariant {
  primary,
  outlined,
  destructive,
  darkCta,
  text,
}

/// Unified, accessible button component conforming to the Food Fight design system.
/// Primary buttons use brandYellow fill with high-contrast onYellow (maroonDeep) text (>=7:1).
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final CustomButtonVariant variant;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double height;
  final String? priceBadge;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.icon,
    this.width = double.infinity,
    this.height = AppDimens.buttonHeight,
  })  : variant = CustomButtonVariant.primary,
        priceBadge = null;

  const CustomButton.outlined({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.icon,
    this.width = double.infinity,
    this.height = AppDimens.buttonHeight,
  })  : variant = CustomButtonVariant.outlined,
        priceBadge = null;

  const CustomButton.destructive({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height = AppDimens.buttonHeight,
  })  : variant = CustomButtonVariant.destructive,
        color = AppColors.error,
        textColor = AppColors.error,
        priceBadge = null;

  const CustomButton.darkCta({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon = Icons.shopping_bag_rounded,
    this.width = double.infinity,
    this.height = 56.0,
    this.priceBadge,
  })  : variant = CustomButtonVariant.darkCta,
        color = AppColors.ctaDark,
        textColor = Colors.white;

  const CustomButton.text({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.textColor,
  })  : variant = CustomButtonVariant.text,
        color = null,
        width = null,
        height = 44.0,
        priceBadge = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (variant) {
      case CustomButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: textColor ?? (isDark ? AppColors.darkAmberDark : AppColors.amberDark),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radius12)),
          ),
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor ?? (isDark ? AppColors.darkAmberDark : AppColors.amberDark),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      text,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        );

      case CustomButtonVariant.darkCta:
        return SizedBox(
          width: width,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.ctaDark,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: isDark ? 0.45 : 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.brandYellow,
                          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                        ),
                        child: Icon(
                          icon ?? Icons.shopping_bag_rounded,
                          color: AppColors.onYellow,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (priceBadge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                          ),
                          child: Text(
                            priceBadge!,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
          ),
        );

      case CustomButtonVariant.destructive:
        return SizedBox(
          width: width,
          height: height,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radius16),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
          ),
        );

      case CustomButtonVariant.outlined:
        return SizedBox(
          width: width,
          height: height,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor ?? (isDark ? AppColors.brandYellow : AppColors.brandMaroon),
              side: BorderSide(
                color: color ?? (isDark ? AppColors.brandYellow : AppColors.brandMaroon),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radius16),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor ?? (isDark ? AppColors.brandYellow : AppColors.brandMaroon),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: textColor ?? (isDark ? AppColors.brandYellow : AppColors.brandMaroon),
                        ),
                      ),
                    ],
                  ),
          ),
        );

      case CustomButtonVariant.primary:
        final btnColor = color ?? AppColors.brandYellow;
        final fgColor = textColor ?? AppColors.onYellow;

        return SizedBox(
          width: width,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              foregroundColor: fgColor,
              disabledBackgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
              disabledForegroundColor: AppColors.textMuted,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radius16),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: fgColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 19, color: fgColor),
                        const SizedBox(width: 8),
                      ],
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          text,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            color: fgColor,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
    }
  }
}
