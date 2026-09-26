import 'package:flutter/material.dart';

/// Breakpoint definitions for consistent multi-platform adaptation
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 960;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  /// Calculate optimal grid columns based on available width
  static int responsiveColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= ResponsiveBreakpoints.desktop) return desktop;
    if (width >= ResponsiveBreakpoints.mobile) return tablet;
    return mobile;
  }
}

/// A wrapper container that centers content and enforces max-width constraints
/// preventing undesirable horizontal stretching on large displays/desktops.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1140,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  /// Factory for standard form layouts (Auth, Modal, Checkout dialogs)
  factory ResponsiveContainer.form({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double maxWidth = 520,
  }) {
    return ResponsiveContainer(
      key: key,
      maxWidth: maxWidth,
      padding: padding,
      alignment: Alignment.center,
      child: child,
    );
  }

  /// Factory for standard content/dashboard views
  factory ResponsiveContainer.content({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double maxWidth = 1140,
  }) {
    return ResponsiveContainer(
      key: key,
      maxWidth: maxWidth,
      padding: padding,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}
