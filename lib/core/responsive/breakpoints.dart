import 'package:flutter/material.dart';

/// Material 3 Window Size Classes based on usable screen/pane width:
/// - compact: < 600 dp (Phone portrait, narrow split-screen)
/// - medium: 600 - 839 dp (Tablet portrait, foldable unfolded, phone landscape)
/// - expanded: 840 - 1199 dp (Tablet landscape, small desktop window, laptop)
/// - large: >= 1200 dp (Desktop monitor, large laptop screen, wide window)
enum WindowSizeClass {
  compact,
  medium,
  expanded,
  large;

  bool get isCompact => this == WindowSizeClass.compact;
  bool get isMedium => this == WindowSizeClass.medium;
  bool get isExpanded => this == WindowSizeClass.expanded;
  bool get isLarge => this == WindowSizeClass.large;

  bool get isMediumOrWider => this != WindowSizeClass.compact;
  bool get isExpandedOrWider => this == WindowSizeClass.expanded || this == WindowSizeClass.large;

  /// Resolves the size class from a raw width in density-independent pixels.
  static WindowSizeClass fromWidth(double width) {
    if (width < 600) return WindowSizeClass.compact;
    if (width < 840) return WindowSizeClass.medium;
    if (width < 1200) return WindowSizeClass.expanded;
    return WindowSizeClass.large;
  }

  /// Resolves the size class from the inherited [BuildContext] using efficient `MediaQuery.sizeOf`.
  static WindowSizeClass of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }
}

/// Breakpoints and device identification utilities
class ResponsiveBreakpoints {
  static const double compactMax = 599.9;
  static const double mediumMin = 600.0;
  static const double mediumMax = 839.9;
  static const double expandedMin = 840.0;
  static const double expandedMax = 1199.9;
  static const double largeMin = 1200.0;

  /// True if device physical form factor is a phone (shortest side < 600).
  /// Distinguishes a phone in landscape (where width may be > 600) from a real tablet.
  static bool isPhoneDevice(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.shortestSide < 600;
  }

  /// True if device physical form factor is a tablet (shortest side >= 600).
  static bool isTabletDevice(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 && size.shortestSide < 900;
  }

  /// True if device is desktop or large web screen (width >= 1200).
  static bool isDesktopOrWeb(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= largeMin;
  }
}
