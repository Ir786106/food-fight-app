import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/models/admin/admin_account_model.dart';
import 'package:food_fight/providers/admin_account_provider.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/core/theme/super_admin_theme.dart';
import 'package:food_fight/widgets/super_admin/super_admin_drawer.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/empty_state_view.dart';
import 'package:food_fight/widgets/common/error_view.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'package:food_fight/core/utils/validator_utils.dart';

class SuperAdminManageAdminsScreen extends StatefulWidget {
  const SuperAdminManageAdminsScreen({super.key});

  @override
  State<SuperAdminManageAdminsScreen> createState() => _SuperAdminManageAdminsScreenState();
}

class _SuperAdminManageAdminsScreenState extends State<SuperAdminManageAdminsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<Map<String, String>> _availablePermissions = [
    {'id': 'manage_menu', 'label': 'Menu & Categories'},
    {'id': 'manage_orders', 'label': 'Live Order Management'},
    {'id': 'manage_coupons', 'label': 'Coupons & Deals'},
    {'id': 'manage_customers', 'label': 'Customer Accounts'},
    {'id': 'manage_delivery', 'label': 'Delivery Zones & Fees'},
    {'id': 'view_reports', 'label': 'Sales Analytics & Reports'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAdminDialog({AdminAccountModel? admin}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: admin?.name ?? '');
    final emailCtrl = TextEditingController(text: admin?.email ?? '');
    final phoneCtrl = TextEditingController(text: admin?.phone ?? '');
    String selectedRole = admin?.role ?? 'admin';
    final selectedPermissions = Set<String>.from(
      admin?.permissions ?? ['manage_menu', 'manage_orders', 'view_reports'],
    );
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: SuperAdminTheme.getCardBg(dialogContext),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              admin == null ? 'Create Admin / Staff Account' : 'Edit Account & Permissions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: SuperAdminTheme.getTextDark(dialogContext),
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Full Name'),
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g. John Doe',
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: admin == null,
                      validator: ValidatorUtils.validateEmail,
                      decoration: InputDecoration(
                        labelText: 'Email Address *',
                        hintText: 'e.g. admin@foodfight.pk',
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Phone'),
                      decoration: InputDecoration(
                        labelText: 'Phone Number *',
                        hintText: 'e.g. +92 300 1234567',
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Account Role',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: SuperAdminTheme.getTextDark(dialogContext),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedRole,
                          items: const [
                            DropdownMenuItem(value: 'admin', child: Text('Branch Admin')),
                            DropdownMenuItem(value: 'staff', child: Text('Kitchen / Store Staff')),
                            DropdownMenuItem(value: 'super_admin', child: Text('Super Administrator')),
                          ],
                          onChanged: (val) => setDialogState(() => selectedRole = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Assigned Permissions',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: SuperAdminTheme.getTextDark(dialogContext),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._availablePermissions.map((perm) {
                      final hasPerm = selectedPermissions.contains(perm['id']);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(perm['label']!, style: const TextStyle(fontSize: 13)),
                        value: hasPerm,
                        activeColor: SuperAdminTheme.primary,
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              selectedPermissions.add(perm['id']!);
                            } else {
                              selectedPermissions.remove(perm['id']!);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SuperAdminTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final currentUserName = context.read<AuthProvider>().currentUser?.name;

                        setDialogState(() => isSaving = true);
                        try {
                          final provider = context.read<AdminAccountProvider>();

                          if (admin == null) {
                            await provider.createAdminAccount(
                              AdminAccountModel(
                                id: '',
                                name: name,
                                email: email,
                                phone: phone,
                                role: selectedRole,
                                status: 'active',
                                permissions: selectedPermissions.toList(),
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                              createdBy: currentUserName,
                            );
                          } else {
                            await provider.updateAdminAccount(
                              admin.copyWith(
                                name: name,
                                phone: phone,
                                role: selectedRole,
                                permissions: selectedPermissions.toList(),
                                updatedAt: DateTime.now(),
                              ),
                              updatedBy: currentUserName,
                            );
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(admin == null ? 'Create Account' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStatusActionSheet(AdminAccountModel admin) {
    final currentUserName = context.read<AuthProvider>().currentUser?.name;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Account Status: ${admin.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
                title: const Text('Activate Account'),
                subtitle: const Text('Grant immediate access to admin features'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<AdminAccountProvider>().setAdminStatus(
                    admin.id,
                    'active',
                    changedBy: currentUserName,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.pause_circle_rounded, color: Colors.orange),
                title: const Text('Suspend Account'),
                subtitle: const Text('Temporarily prevent admin login and access'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<AdminAccountProvider>().setAdminStatus(
                    admin.id,
                    'suspended',
                    changedBy: currentUserName,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_rounded, color: Colors.red),
                title: const Text('Deactivate Account'),
                subtitle: const Text('Permanently revoke access credentials'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<AdminAccountProvider>().setAdminStatus(
                    admin.id,
                    'deactivated',
                    changedBy: currentUserName,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = SuperAdminTheme.getCardBg(context);
    final textDark = SuperAdminTheme.getTextDark(context);
    final textMuted = SuperAdminTheme.getTextMuted(context);

    final provider = context.watch<AdminAccountProvider>();
    final admins = provider.filteredAdmins;

    return Scaffold(
      backgroundColor: SuperAdminTheme.getBackground(context),
      drawer: const SuperAdminDrawer(currentRoute: '/super-admin/admins'),
      appBar: AppBar(
        title: const Text(
          'Admin & Staff Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: SuperAdminTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add Admin',
            onPressed: () => _openAdminDialog(),
          ),
        ],
      ),
      body: ResponsiveContainer.content(
        maxWidth: 1200,
        child: Column(
          children: [
            // Search and Add Button Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => provider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email or phone...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SuperAdminTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openAdminDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Account', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // Role Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildRoleChip('all', 'All Roles', provider),
                  _buildRoleChip('admin', 'Branch Admins', provider),
                  _buildRoleChip('staff', 'Kitchen Staff', provider),
                  _buildRoleChip('super_admin', 'Super Admins', provider),
                ],
              ),
            ),

            // Admins List
            Expanded(
              child: provider.isLoading && provider.admins.isEmpty
                  ? const LoadingIndicator(message: 'Loading admin accounts...')
                  : provider.errorMessage != null && provider.admins.isEmpty
                      ? ErrorView(
                          message: provider.errorMessage!,
                          onRetry: () => provider.watchAdminAccounts(),
                        )
                      : admins.isEmpty
                          ? EmptyStateView(
                              icon: Icons.admin_panel_settings_outlined,
                              title: 'No Accounts Found',
                              description: 'No admin or staff accounts matching your current search filter.',
                              buttonText: 'Add First Admin',
                              onButtonPressed: () => _openAdminDialog(),
                            )
                          : RefreshIndicator(
                              onRefresh: () async => provider.watchAdminAccounts(),
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: admins.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final admin = admins[index];

                                  return Material(
                                    color: cardBg,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 22,
                                                backgroundColor: SuperAdminTheme.primary.withValues(alpha: 0.12),
                                                child: Text(
                                                  admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: SuperAdminTheme.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            admin.name,
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.w700,
                                                              fontSize: 15,
                                                              color: textDark,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        _buildRoleBadge(admin.role),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${admin.email} • ${admin.phone}',
                                                      style: TextStyle(color: textMuted, fontSize: 12.5),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              _buildStatusBadge(admin.status),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Permissions Chips
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: admin.permissions.map((p) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  p.replaceAll('_', ' '),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: textMuted,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const Divider(height: 20),

                                          // Action Buttons Row
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                icon: const Icon(Icons.tune_rounded, size: 16),
                                                label: const Text('Permissions'),
                                                onPressed: () => _openAdminDialog(admin: admin),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton.icon(
                                                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                                label: const Text('Change Status'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: SuperAdminTheme.primary,
                                                  side: const BorderSide(color: SuperAdminTheme.primary),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                                onPressed: () => _showStatusActionSheet(admin),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: SuperAdminTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openAdminDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('New Admin'),
      ),
    );
  }

  Widget _buildRoleChip(String role, String label, AdminAccountProvider provider) {
    final isSel = provider.roleFilter == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSel,
        selectedColor: SuperAdminTheme.primary,
        labelStyle: TextStyle(
          color: isSel ? Colors.white : Colors.grey.shade800,
          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
        ),
        onSelected: (val) {
          if (val) provider.setRoleFilter(role);
        },
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color = Colors.blue;
    if (role == 'super_admin') color = SuperAdminTheme.accentGold;
    if (role == 'staff') color = Colors.teal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.green;
    if (status == 'suspended') color = Colors.orange;
    if (status == 'deactivated') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
