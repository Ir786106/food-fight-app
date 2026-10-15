import 'package:flutter/material.dart';
import 'breakpoints.dart';
import 'responsive_tokens.dart';

typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
  WindowSizeClass sizeClass,
);

/// Adaptive layout widget that renders different UI trees based on local available width.
/// Built on [LayoutBuilder] so widgets embedded in split-screens, panels, or sidebars
/// react to their actual container width rather than the full screen window width.
///
/// Falls back downward:
/// - large -> expanded -> medium -> compact
/// - expanded -> medium -> compact
/// - medium -> compact
/// [compact] builder is always required.
class AdaptiveLayout extends StatelessWidget {
  final ResponsiveWidgetBuilder compact;
  final ResponsiveWidgetBuilder? medium;
  final ResponsiveWidgetBuilder? expanded;
  final ResponsiveWidgetBuilder? large;

  const AdaptiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If maxWidth is infinite (e.g. inside unconstrained scrollable), fall back to MediaQuery
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final sizeClass = WindowSizeClass.fromWidth(availableWidth);

        switch (sizeClass) {
          case WindowSizeClass.large:
            if (large != null) return large!(context, constraints, sizeClass);
            if (expanded != null) return expanded!(context, constraints, sizeClass);
            if (medium != null) return medium!(context, constraints, sizeClass);
            return compact(context, constraints, sizeClass);

          case WindowSizeClass.expanded:
            if (expanded != null) return expanded!(context, constraints, sizeClass);
            if (medium != null) return medium!(context, constraints, sizeClass);
            return compact(context, constraints, sizeClass);

          case WindowSizeClass.medium:
            if (medium != null) return medium!(context, constraints, sizeClass);
            return compact(context, constraints, sizeClass);

          case WindowSizeClass.compact:
            return compact(context, constraints, sizeClass);
        }
      },
    );
  }
}

/// Centers content horizontally and bounds it to [maxWidth] on tablets, laptops, and wide desktop screens.
class ResponsiveBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveBox({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveTokens.contentMaxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  /// Factory for auth screens (login, signup, reset password)
  const ResponsiveBox.auth({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveTokens.authMaxWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.alignment = Alignment.center,
  });

  /// Factory for forms and checkout steps
  const ResponsiveBox.form({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveTokens.formMaxWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    this.alignment = Alignment.topCenter,
  });

  /// Factory for admin and customer dashboards
  const ResponsiveBox.dashboard({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveTokens.dashboardMaxWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// A responsive grid delegate helper that calculates cross axis count cleanly
/// using maxCrossAxisExtent clamped between min and max columns.
class ResponsiveGridConfig {
  static int calculateColumns({
    required double width,
    double itemWidth = 180.0,
    int minColumns = 2,
    int maxColumns = 6,
  }) {
    final cols = (width / itemWidth).floor();
    return cols.clamp(minColumns, maxColumns);
  }
}
