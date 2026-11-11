import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/localization/app_language.dart';
import '../../../models/branch_model.dart';
import '../../../services/branch_service.dart';
import '../../../services/super_admin_service.dart';
import '../../../widgets/super_admin/super_admin_scaffold.dart';

class SuperAdminBranchesScreen extends StatefulWidget {
  const SuperAdminBranchesScreen({
    super.key,
    this.watchBranches = BranchService.watchPlatformBranches,
  });

  final Stream<List<BranchModel>> Function() watchBranches;

  @override
  State<SuperAdminBranchesScreen> createState() =>
      _SuperAdminBranchesScreenState();
}

class _SuperAdminBranchesScreenState extends State<SuperAdminBranchesScreen> {
  late Stream<List<BranchModel>> _branches;
  final _updating = <String>{};

  @override
  void initState() {
    super.initState();
    _branches = widget.watchBranches();
  }

  Future<void> _changeStatus(BranchModel branch) async {
    if (_updating.contains(branch.id)) return;
    final activate = !branch.isActive;
    final confirmed = await AppDialog.show<bool>(
        context,
        (dialogContext) => AlertDialog(
              scrollable: true,
              title: Text(dialogContext.tr(
                  activate ? 'Reactivate branch?' : 'Suspend branch?')),
              content: Text(dialogContext
                  .tr(activate
                      ? '{branch} will accept new orders again.'
                      : '{branch} will stop accepting new orders. Existing deliveries can continue.')
                  .replaceFirst('{branch}', branch.name)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(dialogContext.tr('Cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(dialogContext.tr(activate ? 'Reactivate' : 'Suspend')),
                ),
              ],
            ));
    if (!mounted || confirmed != true || !_updating.add(branch.id)) return;
    setState(() {});
    try {
      await SuperAdminService.setBranchStatus(branch.id, active: activate);
      if (mounted) {
        AppSnackbar.showSuccess(context, context.tr('Branch status updated.'));
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(context, context.tr('Unable to update this branch.'));
      }
    } finally {
      if (mounted) setState(() => _updating.remove(branch.id));
    }
  }

  void _preview(BranchModel branch) {
    AppDialog.show<void>(
        context,
        (dialogContext) => AlertDialog(
              scrollable: true,
              title: Text(branch.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text([branch.address, branch.city]
                      .where((part) => part.isNotEmpty)
                      .join(', ')),
                  if (branch.phone.isNotEmpty)
                    Text(branch.phone, textDirection: TextDirection.ltr),
                  Text(branch.openingHours),
                  Text(dialogContext.tr('Delivery radius: {radius} km')
                      .replaceFirst('{radius}', branch.deliveryRadiusKm.toString())),
                  Text(dialogContext.tr('Recorded orders: {count}').replaceFirst(
                      '{count}',
                      MaterialLocalizations.of(dialogContext).formatDecimal(branch.orderCount))),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(dialogContext.tr('Close'))),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) => SuperAdminScaffold(
        currentRoute: '/super-admin/branches',
        appBar: AppBar(
          title: Text(context.tr('Restaurant branches')),
          actions: [
            IconButton(
              tooltip: context.tr('Create branch and admin'),
              icon: const Icon(Icons.add_business_outlined),
              onPressed: () => Navigator.of(context)
                  .pushNamed('/super-admin/admins', arguments: 'create-branch'),
            ),
          ],
        ),
        body: StreamBuilder<List<BranchModel>>(
          stream: _branches,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorView(
                message: context.tr('Unable to load restaurant branches.'),
                onRetry: () =>
                    setState(() => _branches = widget.watchBranches()),
              );
            }
            final branches = snapshot.data;
            if (branches == null) {
              return const Padding(
                padding: DesignSystem.screenPadding,
                child: ShimmerLoader(height: 144),
              );
            }
            if (branches.isEmpty) {
              return EmptyStateView(
                icon: Icons.storefront_outlined,
                title: context.tr('No restaurant branches'),
                description: context.tr(
                    'Create a branch and provision its first administrator.'),
              );
            }
            return ListView.builder(
              padding: DesignSystem.screenPadding,
              itemCount: branches.length,
              itemBuilder: (context, index) {
                final branch = branches[index];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: branch.name,
                        action: StatusChip(
                          label: context.tr(branch.isActive ? 'Active' : 'Suspended'),
                          tone: branch.isActive
                              ? StatusTone.success
                              : StatusTone.warning,
                        ),
                      ),
                      Text(branch.city),
                      Wrap(
                        spacing: DesignSystem.space8,
                        children: [
                          TextButton(
                            onPressed: () => _preview(branch),
                            child: Text(context.tr('Preview branch')),
                          ),
                          TextButton(
                            onPressed: _updating.contains(branch.id)
                                ? null
                                : () => _changeStatus(branch),
                            child: Text(context.tr(
                                branch.isActive ? 'Suspend' : 'Reactivate')),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
}
