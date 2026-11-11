import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../models/user_model.dart';
import '../../../services/super_admin_service.dart';
import '../../../widgets/super_admin/super_admin_scaffold.dart';

class SuperAdminUsersScreen extends StatefulWidget {
  const SuperAdminUsersScreen({super.key});

  @override
  State<SuperAdminUsersScreen> createState() => _SuperAdminUsersScreenState();
}

class _SuperAdminUsersScreenState extends State<SuperAdminUsersScreen> {
  static const _filters = <String, List<String>>{
    'All roles': [],
    'Customers': ['customer'],
    'Riders': ['rider', 'delivery_rider'],
    'Branch admins': ['admin'],
    'Staff': ['staff', 'sub_admin'],
    'Super admins': ['super_admin'],
  };

  String _filter = 'All roles';
  String? _after;
  final _previous = <String?>[];
  late Future<({List<UserModel> users, bool hasMore})> _page;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _page = SuperAdminService.fetchUserPage(
        roles: _filters[_filter]!, after: _after);
  }

  @override
  Widget build(BuildContext context) => SuperAdminScaffold(
        currentRoute: '/super-admin/users',
        appBar: AppBar(title: const Text('Platform user directory')),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: DesignSystem.screenPadding,
              child: DropdownButton<String>(
                value: _filter,
                items: [
                  for (final label in _filters.keys)
                    DropdownMenuItem(value: label, child: Text(label)),
                ],
                onChanged: (label) {
                  if (label == null || label == _filter) return;
                  setState(() {
                    _filter = label;
                    _previous.clear();
                    _after = null;
                    _load();
                  });
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<({List<UserModel> users, bool hasMore})>(
                future: _page,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: DesignSystem.screenPadding,
                      child: ShimmerLoader(height: 144),
                    );
                  }
                  final page = snapshot.data;
                  if (page == null) {
                    return ErrorView(
                      message: 'Unable to load users.',
                      onRetry: () => setState(_load),
                    );
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: page.users.isEmpty
                            ? const EmptyStateView(
                                icon: Icons.people_outline,
                                title: 'No users on this page',
                                description:
                                    'Try another role or return to the previous page.',
                              )
                            : ListView.builder(
                                padding: DesignSystem.screenPadding,
                                itemCount: page.users.length,
                                itemBuilder: (context, index) {
                                  final user = page.users[index];
                                  return ListTile(
                                    title: Text(user.name),
                                    subtitle: Text(
                                      [user.email, user.role, user.branchId]
                                          .whereType<String>()
                                          .where((value) => value.isNotEmpty)
                                          .join(' · '),
                                    ),
                                    trailing: StatusChip(
                                      label:
                                          user.isActive ? 'Active' : 'Inactive',
                                      tone: user.isActive
                                          ? StatusTone.success
                                          : StatusTone.warning,
                                    ),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: DesignSystem.screenPadding,
                        child: Wrap(
                          spacing: DesignSystem.space16,
                          children: [
                            AppButton(
                              style: AppButtonStyle.ghost,
                              label: 'Previous page',
                              onPressed: _previous.isEmpty
                                  ? null
                                  : () => setState(() {
                                        _after = _previous.removeLast();
                                        _load();
                                      }),
                            ),
                            AppButton(
                              style: AppButtonStyle.secondary,
                              label: 'Next page',
                              onPressed: !page.hasMore || page.users.isEmpty
                                  ? null
                                  : () => setState(() {
                                        _previous.add(_after);
                                        _after = page.users.last.id;
                                        _load();
                                      }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
}
