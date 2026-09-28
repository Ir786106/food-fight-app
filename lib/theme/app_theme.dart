import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified Food Fight brand color scheme.
/// Primary: Food Fight Yellow (#FFC700)
/// Secondary / Dark: Dark Brown / Chocolate (#3C1810)
/// Surface: White (#FFFFFF)
/// Background: Cream / Warm Neutral (#FAF6F0)
/// Text: Dark Neutral / Black (#2E1A11)
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

  // Dark theme tokens (Deep Chocolate / Near-black)
  static const Color darkBackground = Color(0xFF170F0B);
  static const Color darkSurface = Color(0xFF231812);
  static const Color darkSurfaceElevated = Color(0xFF2E2018);
  static const Color darkTextPrimary = Color(0xFFFAF6F0);
  static const Color darkTextSecondary = Color(0xFFA6968E);
  static const Color darkDivider = Color(0xFF382921);

  // Status tokens (semantic only)
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3C1810);
}

class AppTheme {
  /// Light Theme
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primaryYellow,
      onPrimary: AppColors.darkBrown,
      primaryContainer: AppColors.lightCream,
      onPrimaryContainer: AppColors.darkBrown,
      secondary: AppColors.darkBrown,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.lightCream,
      onSecondaryContainer: AppColors.darkBrown,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      error: AppColors.error,
      onError: Colors.white,
      shadow: Color(0x14000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryYellow,
      cardColor: AppColors.surface,
      dividerColor: AppColors.divider,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.darkBrown,
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkBrown,
          side: const BorderSide(color: AppColors.darkBrown, width: 1.2),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryYellow,
        unselectedItemColor: AppColors.darkBrown,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primaryYellow,
      onPrimary: AppColors.darkBrown,
      primaryContainer: Color(0xFF2E2018),
      onPrimaryContainer: AppColors.primaryYellow,
      secondary: AppColors.darkBrown,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF2E2018),
      onSecondaryContainer: AppColors.darkTextPrimary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceElevated,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: Color(0xFF382921),
      outlineVariant: AppColors.darkDivider,
      error: AppColors.error,
      onError: Colors.white,
      shadow: Color(0x66000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primaryYellow,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkDivider,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData(brightness: Brightness.dark).textTheme).apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
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
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0x18FFFFFF), width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.darkBrown,
          minimumSize: const Size(64, 52),
          elevation: 2,
          shadowColor: AppColors.primaryYellow.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          side: const BorderSide(color: AppColors.darkDivider, width: 1.2),
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.poppins(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryYellow,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
    );
  }
}
