import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Performance-optimized BuildContext extension for responsive layouts.
/// Uses `MediaQuery.sizeOf(this)` and `MediaQuery.textScalerOf(this)` to avoid
/// rebuilding the entire widget tree when unrelated MediaQuery data (e.g. viewInsets or orientation padding) changes.
extension ResponsiveContextExtension on BuildContext {
  /// Usable screen size
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Usable screen width
  double get screenWidth => screenSize.width;

  /// Usable screen height
  double get screenHeight => screenSize.height;

  /// Current text scaler
  TextScaler get textScaler => MediaQuery.textScalerOf(this);

  /// Current text scale factor (numeric, e.g. 1.0, 1.3, 2.0)
  double get textScale => textScaler.scale(1.0);

  /// Current window size class based on usable screen width
  WindowSizeClass get windowSizeClass => WindowSizeClass.fromWidth(screenWidth);

  /// Short alias for windowSizeClass
  WindowSizeClass get screen => windowSizeClass;

  /// Window size class checks
  bool get isCompact => windowSizeClass == WindowSizeClass.compact;
  bool get isMedium => windowSizeClass == WindowSizeClass.medium;
  bool get isExpanded => windowSizeClass == WindowSizeClass.expanded;
  bool get isLarge => windowSizeClass == WindowSizeClass.large;

  /// Convenience flags
  bool get isMediumOrWider => !isCompact;
  bool get isExpandedOrWider => isExpanded || isLarge;

  /// Form factor checks based on shortestSide
  bool get isPhone => ResponsiveBreakpoints.isPhoneDevice(this);
  bool get isTablet => ResponsiveBreakpoints.isTabletDevice(this);
  bool get isDesktopOrWeb => ResponsiveBreakpoints.isDesktopOrWeb(this);

  /// Returns column count appropriate for current width
  int columns({
    int compact = 1,
    int medium = 2,
    int expanded = 3,
    int large = 4,
  }) {
    switch (windowSizeClass) {
      case WindowSizeClass.compact:
        return compact;
      case WindowSizeClass.medium:
        return medium;
      case WindowSizeClass.expanded:
        return expanded;
      case WindowSizeClass.large:
        return large;
    }
  }

  /// Calculates dynamic item grid columns based on item width target (e.g. ~180px for product cards)
  int dynamicGridColumns({
    double targetItemWidth = 180.0,
    int min = 2,
    int max = 6,
  }) {
    final cols = (screenWidth / targetItemWidth).floor();
    return cols.clamp(min, max);
  }
}
