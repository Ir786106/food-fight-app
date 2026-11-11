import 'package:flutter/material.dart';

class AppDestination {
  const AppDestination({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

class AppAdaptiveNavigation extends StatefulWidget {
  const AppAdaptiveNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.expandLabel,
    required this.collapseLabel,
    required this.body,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String expandLabel;
  final String collapseLabel;
  final Widget body;

  @override
  State<AppAdaptiveNavigation> createState() => _AppAdaptiveNavigationState();
}

class _AppAdaptiveNavigationState extends State<AppAdaptiveNavigation> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final mobile = width < 600;
          final desktop = width > 1024;
          return Scaffold(
            bottomNavigationBar: mobile
                ? NavigationBar(
                    selectedIndex: widget.selectedIndex,
                    onDestinationSelected: widget.onSelected,
                    destinations: [
                      for (final item in widget.destinations)
                        NavigationDestination(
                            icon: Icon(item.icon), label: item.label),
                    ],
                  )
                : null,
            body: Row(
              children: [
                if (!mobile)
                  SafeArea(
                    child: NavigationRail(
                      extended: desktop && _expanded,
                      scrollable: true,
                      leading: desktop
                          ? IconButton(
                              tooltip: _expanded
                                  ? widget.collapseLabel
                                  : widget.expandLabel,
                              onPressed: () =>
                                  setState(() => _expanded = !_expanded),
                              icon: const Icon(Icons.menu),
                            )
                          : null,
                      selectedIndex: widget.selectedIndex,
                      onDestinationSelected: widget.onSelected,
                      destinations: [
                        for (final item in widget.destinations)
                          NavigationRailDestination(
                              icon: Icon(item.icon), label: Text(item.label)),
                      ],
                    ),
                  ),
                Expanded(
                    key: const ValueKey('destination-body'),
                    child: widget.body),
              ],
            ),
          );
        },
      );
}
