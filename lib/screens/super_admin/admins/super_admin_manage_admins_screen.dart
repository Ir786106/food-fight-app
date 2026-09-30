import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/models/admin/admin_account_model.dart';
import 'package:food_fight/providers/admin_account_provider.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/providers/branch_provider.dart';
import 'package:food_fight/models/branch_model.dart';
import 'package:food_fight/services/branch_service.dart';
import 'package:food_fight/core/theme/super_admin_theme.dart';
import 'package:food_fight/theme/app_theme.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminAccountProvider>().watchAdminAccounts();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openNewBranchDialog() {
    final formKey = GlobalKey<FormState>();
    final branchNameCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Lahore');
    final addressCtrl = TextEditingController();
    final branchPhoneCtrl = TextEditingController();
    final adminNameCtrl = TextEditingController();
    final adminEmailCtrl = TextEditingController();
    final adminPhoneCtrl = TextEditingController();
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
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SuperAdminTheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_business_rounded, color: SuperAdminTheme.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Open New Branch & Assign Admin',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: SuperAdminTheme.getTextDark(dialogContext),
                    ),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. Branch Location Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SuperAdminTheme.primary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: branchNameCtrl,
                        validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Branch name'),
                        decoration: InputDecoration(
                          labelText: 'Branch Name *',
                          hintText: 'e.g. Food Fight - Johar Town',
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cityCtrl,
                              validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'City'),
                              decoration: InputDecoration(
                                labelText: 'City *',
                                hintText: 'Lahore, Islamabad...',
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: branchPhoneCtrl,
                              validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Branch phone'),
                              decoration: InputDecoration(
                                labelText: 'Branch Phone *',
                                hintText: '+92 42 35000000',
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: addressCtrl,
                        validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Address'),
                        decoration: InputDecoration(
                          labelText: 'Full Address *',
                          hintText: 'e.g. Main Boulevard, Phase 2, Johar Town',
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      const Text('2. Initial Branch Administrator Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SuperAdminTheme.primary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: adminNameCtrl,
                        validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Admin name'),
                        decoration: InputDecoration(
                          labelText: 'Manager / Admin Full Name *',
                          hintText: 'e.g. Tariq Mehmood',
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: adminEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: ValidatorUtils.validateEmail,
                        decoration: InputDecoration(
                          labelText: 'Admin Email *',
                          hintText: 'manager.johartown@foodfight.pk',
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: adminPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Admin phone'),
                        decoration: InputDecoration(
                          labelText: 'Admin Mobile Number *',
                          hintText: '+92 300 1234567',
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
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
                ),
                onPressed: isSaving ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() => isSaving = true);
                  try {
                    final branchName = branchNameCtrl.text.trim();
                    final city = cityCtrl.text.trim();
                    final slug = branchName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-').replaceAll(RegExp(r'-+'), '-');
                    final newBranchId = 'branch-$slug';

                    // 1. Create Branch document
                    final branch = BranchModel(
                      id: newBranchId,
                      name: branchName,
                      address: addressCtrl.text.trim(),
                      city: city,
                      phone: branchPhoneCtrl.text.trim(),
                      status: 'active',
                      revenue: 0.0,
                      orderCount: 0,
                      expenses: 0.0,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    // Capture providers before async operations
                    final authProv = context.read<AuthProvider>();
                    final adminAccProv = context.read<AdminAccountProvider>();
                    final currentUserName = authProv.currentUser?.name;

                    await BranchService.createBranch(branch);

                    // 2. Create Branch Admin account
                    await adminAccProv.createAdminAccount(
                      AdminAccountModel(
                        id: '',
                        name: adminNameCtrl.text.trim(),
                        email: adminEmailCtrl.text.trim().toLowerCase(),
                        phone: adminPhoneCtrl.text.trim(),
                        role: 'admin',
                        status: 'active',
                        branchId: newBranchId,
                        permissions: ['manage_menu', 'manage_orders', 'manage_coupons', 'manage_customers', 'manage_delivery', 'view_reports'],
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                      createdBy: currentUserName,
                    );

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Branch "$branchName" & Admin Account created successfully!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error creating branch: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Open Branch & Assign Admin'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openAdminDialog({AdminAccountModel? admin}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: admin?.name ?? '');
    final emailCtrl = TextEditingController(text: admin?.email ?? '');
    final phoneCtrl = TextEditingController(text: admin?.phone ?? '');
    String selectedRole = admin?.role ?? 'admin';
    String? selectedBranchId = admin?.branchId;
    final branches = context.read<BranchProvider>().branches;
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
                    const SizedBox(height: 12),

                    // Branch Assignment Dropdown
                    if (selectedRole != 'super_admin') ...[
                      Text(
                        'Assigned Branch *',
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
                            hint: const Text('Select Branch'),
                            value: selectedBranchId,
                            items: branches.map((b) {
                              return DropdownMenuItem<String>(
                                value: b.id,
                                child: Text('${b.name} (${b.city})'),
                              );
                            }).toList(),
                            onChanged: (val) => setDialogState(() => selectedBranchId = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

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
                        if (selectedRole != 'super_admin' && (selectedBranchId == null || selectedBranchId!.isEmpty)) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please select an assigned branch for this admin/staff')),
                          );
                          return;
                        }

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
                                branchId: selectedRole == 'super_admin' ? null : selectedBranchId,
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
                                branchId: selectedRole == 'super_admin' ? null : selectedBranchId,
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
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
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
                leading: const Icon(Icons.check_circle_rounded, color: AppColors.success),
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
                leading: const Icon(Icons.pause_circle_rounded, color: AppColors.warning),
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
                leading: const Icon(Icons.cancel_rounded, color: AppColors.error),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/super-admin/dashboard');
        }
      },
      child: Scaffold(
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
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _openNewBranchDialog(),
            icon: const Icon(Icons.add_business_rounded, size: 16),
            label: const Text('Open Branch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add Admin',
            onPressed: () => _openAdminDialog(),
          ),
          const SizedBox(width: 8),
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

            // Branch & Role Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  // Branch Selector Dropdown
                  Consumer<BranchProvider>(
                    builder: (context, branchProv, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.branchFilter,
                            isDense: true,
                            style: TextStyle(fontSize: 12.5, color: textDark, fontWeight: FontWeight.w600),
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('All Branches')),
                              ...branchProv.branches.map((b) => DropdownMenuItem(
                                value: b.id,
                                child: Text(b.name, overflow: TextOverflow.ellipsis),
                              )),
                            ],
                            onChanged: (val) {
                              if (val != null) provider.setBranchFilter(val);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildRoleChip('all', 'All Roles', provider),
                          _buildRoleChip('admin', 'Branch Admins', provider),
                          _buildRoleChip('staff', 'Kitchen Staff', provider),
                          _buildRoleChip('super_admin', 'Super Admins', provider),
                        ],
                      ),
                    ),
                  ),
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
                                                        if (admin.isSubAdmin) ...[
                                                          const SizedBox(width: 4),
                                                          _buildSubAdminBadge(),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Row(
                                                      children: [
                                                        _buildBranchTag(admin.branchId, context),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            '${admin.email} • ${admin.phone}',
                                                            style: TextStyle(color: textMuted, fontSize: 12),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
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
    Color color = AppColors.darkBrown;
    if (role == 'super_admin') color = SuperAdminTheme.accentGold;
    if (role == 'staff') color = AppColors.primaryYellow;

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
    Color color = AppColors.success;
    if (status == 'suspended') color = AppColors.warning;
    if (status == 'deactivated') color = AppColors.error;

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

  Widget _buildSubAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppColors.darkBrown.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.darkBrown.withValues(alpha: 0.4)),
      ),
      child: const Text(
        'SUB-ADMIN',
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.darkBrown),
      ),
    );
  }

  Widget _buildBranchTag(String? branchId, BuildContext context) {
    if (branchId == null || branchId.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('HQ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
      );
    }

    final branches = context.read<BranchProvider>().branches;
    final branch = branches.where((b) => b.id == branchId).firstOrNull;
    final name = branch?.name ?? branchId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: SuperAdminTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: SuperAdminTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storefront_rounded, size: 10, color: SuperAdminTheme.primary),
          const SizedBox(width: 3),
          Text(
            name,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: SuperAdminTheme.primary),
          ),
        ],
      ),
    );
  }
}
