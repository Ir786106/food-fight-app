import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/design_system/design_system.dart';

void main() {
  testWidgets('navigation adapts without remounting the page', (tester) async {
    final width = ValueNotifier<double>(599);
    var mounts = 0;
    final page = _Page(onMount: () => mounts++);
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(width.dispose);

    await tester.pumpWidget(MaterialApp(
      home: ValueListenableBuilder<double>(
        valueListenable: width,
        builder: (context, value, _) => Center(
          child: SizedBox(
            width: value,
            child: AppAdaptiveNavigation(
              destinations: const [
                AppDestination(label: 'Home', icon: Icons.home),
                AppDestination(label: 'Orders', icon: Icons.receipt),
              ],
              selectedIndex: 0,
              onSelected: (_) {},
              expandLabel: 'Expand navigation',
              collapseLabel: 'Collapse navigation',
              body: page,
            ),
          ),
        ),
      ),
    ));
    expect(find.byType(NavigationBar), findsOneWidget);

    width.value = 600;
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byTooltip('Expand navigation'), findsNothing);

    width.value = 1025;
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Expand navigation'));
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue);
    expect(mounts, 1);
  });

  testWidgets('loading button ignores presses', (tester) async {
    var presses = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: AppButton(
          label: 'Accept',
          loadingLabel: 'Updating',
          onPressed: () => presses++,
        ),
      ),
    ));
    await tester.tap(find.text('Updating'));
    expect(presses, 0);
  });
}

class _Page extends StatefulWidget {
  const _Page({required this.onMount});
  final VoidCallback onMount;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
