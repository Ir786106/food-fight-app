import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../theme/design_system.dart';

/// A fade shared by named routes on every supported platform.
class AppPageTransitions extends PageTransitionsBuilder {
  const AppPageTransitions();

  static const theme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: AppPageTransitions(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: AppPageTransitions(),
      TargetPlatform.windows: AppPageTransitions(),
      TargetPlatform.linux: AppPageTransitions(),
      TargetPlatform.fuchsia: AppPageTransitions(),
    },
  );

  @override
  Duration get transitionDuration => DesignSystem.durationNormal;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: DesignSystem.curveEnter)),
      child: child,
    );
  }
}

/// Animates numeric changes while allowing the caller to localize the value.
class AppAnimatedCounter extends StatelessWidget {
  const AppAnimatedCounter({
    super.key,
    required this.value,
    required this.format,
  });

  final num value;
  final String Function(num value) format;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Text(format(value));
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: DesignSystem.durationNormal,
      curve: DesignSystem.curveEnter,
      builder: (context, current, _) => Semantics(
        label: format(value),
        excludeSemantics: true,
        child: Text(format(current)),
      ),
    );
  }
}
