import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/constants/app_colors.dart';

/// Calculates the relative luminance of a Color according to WCAG 2.1 specifications.
double calculateLuminance(Color color) {
  double transform(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    } else {
      return pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  final r = transform(color.r);
  final g = transform(color.g);
  final b = transform(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Calculates the contrast ratio between two colors (ranging from 1.0 to 21.0).
double calculateContrastRatio(Color foreground, Color background) {
  final l1 = calculateLuminance(foreground);
  final l2 = calculateLuminance(background);

  final lighter = max(l1, l2);
  final darker = min(l1, l2);

  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('WCAG 2.1 AA Contrast Ratio Tests', () {
    test('Maroon on Brand Yellow meets WCAG AA criteria', () {
      final ratio = calculateContrastRatio(AppColors.brandMaroon, AppColors.brandYellow);
      // Maroon (#6D2123) on Yellow (#FFD505) typically exceeds 7:1
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Maroon on Yellow ratio was ${ratio.toStringAsFixed(2)}:1');
    });

    test('White on Maroon meets WCAG AA criteria', () {
      final ratio = calculateContrastRatio(Colors.white, AppColors.brandMaroon);
      // White (#FFFFFF) on Maroon (#6D2123) exceeds 9:1
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'White on Maroon ratio was ${ratio.toStringAsFixed(2)}:1');
    });

    test('TextPrimary on Light Background meets WCAG AA criteria', () {
      final ratio = calculateContrastRatio(AppColors.textPrimary, AppColors.background);
      // Dark maroon-black (#2A1415) on warm cream-white (#FAF7F2) exceeds 12:1
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'TextPrimary on Background ratio was ${ratio.toStringAsFixed(2)}:1');
    });

    test('TextSecondary on Surface meets WCAG AA Large Text / UI criteria', () {
      final ratio = calculateContrastRatio(AppColors.textSecondary, AppColors.surface);
      // #6B5B58 on #FFFFFF achieves > 4.5:1
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'TextSecondary on Surface ratio was ${ratio.toStringAsFixed(2)}:1');
    });

    test('Dark Theme: Dark TextPrimary on Dark Background meets WCAG AA', () {
      final ratio = calculateContrastRatio(AppColors.darkTextPrimary, AppColors.darkBackground);
      // #F7EFE6 on #140C0B achieves > 13:1
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Dark TextPrimary on Dark Background ratio was ${ratio.toStringAsFixed(2)}:1');
    });

    test('Dark Theme: Brand Yellow on Dark Maroon meets WCAG AA criteria', () {
      final ratio = calculateContrastRatio(AppColors.brandYellow, AppColors.maroonDeep);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Brand Yellow on Maroon Deep ratio was ${ratio.toStringAsFixed(2)}:1');
    });
  });
}
