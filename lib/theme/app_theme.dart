import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

export '../core/constants/app_colors.dart';

/// Food Fight Theme System
/// Built strictly following the Part 1 Professional Brand Design System.
/// Light theme is default.
class AppTheme {
  /// Light Theme (Default)
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.brandYellow,
      onPrimary: AppColors.brandMaroon,
      primaryContainer: AppColors.yellowSoft,
      onPrimaryContainer: AppColors.maroonDeep,
      secondary: AppColors.brandMaroon,
      onSecondary: AppColors.surface,
      secondaryContainer: AppColors.maroonSoft,
      onSecondaryContainer: AppColors.maroonDeep,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceMuted,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      error: AppColors.error,
      onError: AppColors.surface,
      shadow: Color(0x0F2A1415),
    );

    final baseTextTheme = GoogleFonts.interTextTheme();
    final poppinsHeadingTheme = GoogleFonts.poppinsTextTheme();

    final textTheme = baseTextTheme.copyWith(
      displayLarge: poppinsHeadingTheme.displayLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      displayMedium: poppinsHeadingTheme.displayMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      displaySmall: poppinsHeadingTheme.displaySmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      headlineLarge: poppinsHeadingTheme.headlineLarge?.copyWith(
        color: AppColors.brandMaroon,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      headlineMedium: poppinsHeadingTheme.headlineMedium?.copyWith(
        color: AppColors.brandMaroon,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      headlineSmall: poppinsHeadingTheme.headlineSmall?.copyWith(
        color: AppColors.brandMaroon,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleLarge: poppinsHeadingTheme.titleLarge?.copyWith(
        color: AppColors.brandMaroon,
        fontWeight: FontWeight.w600,
        fontSize: 20,
        height: 1.3,
      ),
      titleMedium: poppinsHeadingTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.4,
      ),
      titleSmall: poppinsHeadingTheme.titleSmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.4,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimary,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: poppinsHeadingTheme.labelLarge?.copyWith(
        color: AppColors.brandMaroon,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      labelMedium: poppinsHeadingTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelSmall: poppinsHeadingTheme.labelSmall?.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
        fontSize: 11,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.brandYellow,
      cardColor: AppColors.surface,
      dividerColor: AppColors.divider,
      textTheme: textTheme,
      extensions: const [
        AppStatusColors.light,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.brandMaroon,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.brandMaroon),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.brandMaroon,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        shadowColor: const Color(0x0F2A1415),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandYellow,
          foregroundColor: AppColors.brandMaroon,
          disabledBackgroundColor: AppColors.surfaceMuted,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(64, 52),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandMaroon,
          side: const BorderSide(color: AppColors.brandMaroon, width: 1.5),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandMaroon,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brandMaroon, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.brandMaroon,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.brandMaroon,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.brandMaroon,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.brandYellow, width: 3),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        disabledColor: AppColors.surfaceMuted,
        selectedColor: AppColors.brandYellow,
        labelStyle: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.poppins(
          color: AppColors.brandMaroon,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.maroonDeep,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
        actionTextColor: AppColors.brandYellow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: AppColors.border,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brandYellow;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brandMaroon;
          return AppColors.border;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brandMaroon;
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.brandYellow),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  /// Dark Theme (Sleek Dark fast-food experience)
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.brandYellow,
      onPrimary: AppColors.maroonDeep,
      primaryContainer: AppColors.darkSurfaceElevated,
      onPrimaryContainer: AppColors.brandYellow,
      secondary: AppColors.brandYellow,
      onSecondary: AppColors.maroonDeep,
      secondaryContainer: AppColors.darkSurfaceElevated,
      onSecondaryContainer: AppColors.darkTextPrimary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceElevated,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkDivider,
      error: AppColors.darkError,
      onError: Colors.white,
      shadow: Color(0x66000000),
    );

    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    final poppinsHeadingTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);

    final textTheme = baseTextTheme.copyWith(
      displayLarge: poppinsHeadingTheme.displayLarge?.copyWith(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: poppinsHeadingTheme.headlineMedium?.copyWith(
        color: AppColors.brandYellow,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: poppinsHeadingTheme.headlineSmall?.copyWith(
        color: AppColors.brandYellow,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: poppinsHeadingTheme.titleLarge?.copyWith(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleMedium: poppinsHeadingTheme.titleMedium?.copyWith(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: AppColors.darkTextPrimary,
        fontSize: 16,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.darkTextPrimary,
        fontSize: 14,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: AppColors.darkTextSecondary,
        fontSize: 12,
      ),
      labelLarge: poppinsHeadingTheme.labelLarge?.copyWith(
        color: AppColors.brandYellow,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.brandYellow,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkDivider,
      textTheme: textTheme,
      extensions: const [
        AppStatusColors.dark,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandYellow,
          foregroundColor: AppColors.maroonDeep,
          disabledBackgroundColor: AppColors.darkSurfaceElevated,
          disabledForegroundColor: AppColors.darkTextMuted,
          minimumSize: const Size(64, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandYellow,
          side: const BorderSide(color: AppColors.brandYellow, width: 1.5),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brandYellow, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkError, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.darkTextMuted,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.brandYellow,
        unselectedItemColor: AppColors.darkTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        disabledColor: AppColors.darkSurfaceElevated,
        selectedColor: AppColors.brandYellow,
        labelStyle: GoogleFonts.poppins(
          color: AppColors.darkTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.poppins(
          color: AppColors.maroonDeep,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
