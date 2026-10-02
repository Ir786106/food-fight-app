import 'package:flutter/material.dart';

/// Screen device types
enum DeviceScreenType { mobile, tablet, desktop }

/// Sizing information provided to ResponsiveBuilder
class ResponsiveSizingInformation {
  final DeviceScreenType deviceScreenType;
  final Size screenSize;
  final Size localWidgetSize;

  const ResponsiveSizingInformation({
    required this.deviceScreenType,
    required this.screenSize,
    required this.localWidgetSize,
  });

  bool get isMobile => deviceScreenType == DeviceScreenType.mobile;
  bool get isTablet => deviceScreenType == DeviceScreenType.tablet;
  bool get isDesktop => deviceScreenType == DeviceScreenType.desktop;
}

/// Breakpoint definitions for consistent multi-platform adaptation
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double desktop = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobile && width <= desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > desktop;

  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > desktop) return DeviceScreenType.desktop;
    if (width >= mobile) return DeviceScreenType.tablet;
    return DeviceScreenType.mobile;
  }

  /// Calculate optimal grid columns based on available width
  static int responsiveColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > ResponsiveBreakpoints.desktop) return desktop;
    if (width >= ResponsiveBreakpoints.mobile) return tablet;
    return mobile;
  }
}

/// Responsive builder widget that provides screen size and device information
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveSizingInformation sizingInformation) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, boxConstraints) {
        final deviceType = ResponsiveBreakpoints.getDeviceType(context);
        final sizingInfo = ResponsiveSizingInformation(
          deviceScreenType: deviceType,
          screenSize: mediaQuery.size,
          localWidgetSize: Size(boxConstraints.maxWidth, boxConstraints.maxHeight),
        );
        return builder(context, sizingInfo);
      },
    );
  }
}

/// Adaptive Grid that calculates dynamic column counts and aspect ratios,
/// completely replacing fixed mainAxisExtent and preventing RenderFlex overflows.
class AdaptiveGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double maxCrossAxisExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const AdaptiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.maxCrossAxisExtent = 280.0,
    this.mainAxisSpacing = 12.0,
    this.crossAxisSpacing = 12.0,
    this.childAspectRatio = 1.35,
    this.padding = EdgeInsets.zero,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Dynamically tune ratio for narrow mobile screens to guarantee no overflow
        double effectiveRatio = childAspectRatio;
        if (width < 360) {
          effectiveRatio = childAspectRatio * 0.9;
        } else if (width > 1200) {
          effectiveRatio = childAspectRatio * 1.05;
        }

        return GridView.builder(
          padding: padding,
          physics: physics,
          shrinkWrap: shrinkWrap,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxCrossAxisExtent,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: effectiveRatio,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
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
    this.maxWidth = 1200,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

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

  factory ResponsiveContainer.content({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double maxWidth = 1200,
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

/// Adaptive Scaffold that automatically provides Sidebar on desktop,
/// NavigationRail on tablet, and Drawer / BottomBar on mobile.
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? sidebar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.drawer,
    this.sidebar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop && sidebar != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: Row(
          children: [
            sidebar!,
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      drawer: drawer,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
