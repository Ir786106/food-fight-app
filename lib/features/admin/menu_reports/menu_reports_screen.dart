import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_system.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/repositories/menu_report_repository.dart';

class MenuReportsScreen extends StatelessWidget {
  const MenuReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final branch = user?.branchId?.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Menu issue reports')),
      body: user == null ||
              (!user.isSuperAdmin && (branch == null || branch.isEmpty))
          ? const ErrorView(message: 'A branch assignment is required.')
          : _Reports(
              key: ValueKey((user.id, user.isSuperAdmin, branch)),
              userId: user.id,
              branchId: user.isSuperAdmin ? null : branch,
            ),
    );
  }
}

class _Reports extends StatefulWidget {
  const _Reports({super.key, required this.userId, required this.branchId});
  final String userId;
  final String? branchId;

  @override
  State<_Reports> createState() => _ReportsState();
}

class _ReportsState extends State<_Reports> {
  late Stream<List<MenuReport>> _reports;
  final _updating = <String>{};

  @override
  void initState() {
    super.initState();
    _reports = MenuReportRepository.watch(branchId: widget.branchId);
  }

  Future<void> _toggle(MenuReport report) async {
    if (_updating.contains(report.id)) return;
    setState(() => _updating.add(report.id));
    try {
      await MenuReportRepository.setResolved(
        report,
        updatedBy: widget.userId,
        resolved: !report.resolved,
      );
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(context, 'Could not update the report.');
      }
    } finally {
      if (mounted) setState(() => _updating.remove(report.id));
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<MenuReport>>(
        stream: _reports,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(
              message: 'Could not load menu reports.',
              onRetry: () => setState(() {
                _reports =
                    MenuReportRepository.watch(branchId: widget.branchId);
              }),
            );
          }
          final reports = snapshot.data;
          if (reports == null) {
            return const Padding(
              padding: DesignSystem.screenPadding,
              child: ShimmerLoader(height: 100),
            );
          }
          if (reports.isEmpty) {
            return const EmptyStateView(
              icon: Icons.flag_outlined,
              title: 'No menu issues reported',
              description: 'Customer reports will appear here.',
            );
          }
          return ListView.builder(
            padding: DesignSystem.screenPadding,
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: report.itemName),
                    const SizedBox(height: DesignSystem.space8),
                    Text(report.message),
                    AppButton(
                      style: AppButtonStyle.ghost,
                      label: report.resolved ? 'Reopen' : 'Resolve',
                      loadingLabel:
                          _updating.contains(report.id) ? 'Updating…' : null,
                      onPressed: () => _toggle(report),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
}
