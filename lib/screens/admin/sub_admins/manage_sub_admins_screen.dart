import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/admin/admin_account_model.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/widgets/admin/admin_drawer.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/empty_state_view.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'package:food_fight/core/utils/validator_utils.dart';

class ManageSubAdminsScreen extends StatefulWidget {
  const ManageSubAdminsScreen({super.key});

  @override
  State<ManageSubAdminsScreen> createState() => _ManageSubAdminsScreenState();
}

class _ManageSubAdminsScreenState extends State<ManageSubAdminsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<Map<String, String>> _availablePermissions = [
    {'id': 'orders', 'label': 'Orders & Dispatch', 'icon': 'receipt_long'},
    {'id': 'menu', 'label': 'Menu Items & Modifiers', 'icon': 'restaurant_menu'},
    {'id': 'categories', 'label': 'Food Categories', 'icon': 'category'},
    {'id': 'coupons', 'label': 'Deals & Coupons', 'icon': 'local_offer'},
    {'id': 'customers', 'label': 'Customer Accounts', 'icon': 'people'},
    {'id': 'delivery_areas', 'label': 'Delivery Zones & Fees', 'icon': 'map'},
    {'id': 'riders', 'label': 'Fleet & Riders', 'icon': 'two_wheeler'},
    {'id': 'reports', 'label': 'Sales & Analytics', 'icon': 'insights'},
    {'id': 'chats', 'label': 'Customer Support Chats', 'icon': 'chat'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openSubAdminDialog({AdminAccountModel? existing}) {
    final auth = context.read<AuthProvider>();
    final currentAdmin = auth.currentUser;
    if (currentAdmin == null) return;

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    
    // Default initial permissions
    final selectedPerms = <String>{};
    if (existing != null) {
      selectedPerms.addAll(existing.permissions);
    } else {
      selectedPerms.addAll(['orders', 'menu']);
    }

    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: AdminTheme.getCardBg(dialogCtx),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              existing == null ? 'Create Sub-Admin Account' : 'Edit Sub-Admin Restrictions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AdminTheme.getTextDark(dialogCtx),
              ),
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
                      Text(
                        'Branch: ${currentAdmin.branchId ?? "Main Location"}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AdminTheme.primaryBlue, fontSize: 13),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: nameCtrl,
                        validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Full Name'),
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'e.g. Ali Ahmed',
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        enabled: existing == null,
                        validator: ValidatorUtils.validateEmail,
                        decoration: InputDecoration(
                          labelText: 'Email Address *',
                          hintText: 'e.g. subadmin@foodfight.pk',
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
                          hintText: 'e.g. +92 300 0000000',
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Operational Permissions (Restrictions)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: AdminTheme.getTextDark(dialogCtx),
                        ),
                      ),
                      Text(
                        'Sub-admins can only view and manage sections checked below. Unchecked sections are blocked in both UI and database rules.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AdminTheme.getTextMuted(dialogCtx),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                        ),
                        child: Column(
                          children: _availablePermissions.map((perm) {
                            final permId = perm['id']!;
                            final isChecked = selectedPerms.contains(permId);
                            return CheckboxListTile(
                              dense: true,
                              value: isChecked,
                              title: Text(perm['label']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              activeColor: AdminTheme.primaryBlue,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    selectedPerms.add(permId);
                                  } else {
                                    selectedPerms.remove(permId);
                                  }
                                });
                              },
                            );
                          }).toList(),
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
                  backgroundColor: AdminTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);

                        try {
                          final usersRef = FirebaseFirestore.instance.collection(FirestoreCollections.users);
                          final permissionsMap = <String, bool>{};
                          for (var p in _availablePermissions) {
                            permissionsMap[p['id']!] = selectedPerms.contains(p['id']);
                          }

                          if (existing == null) {
                            final docRef = usersRef.doc();
                            await docRef.set({
                              'id': docRef.id,
                              'uid': docRef.id,
                              'name': nameCtrl.text.trim(),
                              'email': emailCtrl.text.trim().toLowerCase(),
                              'phone': phoneCtrl.text.trim(),
                              'role': 'staff',
                              'status': 'active',
                              'isActive': 1,
                              'branchId': currentAdmin.branchId,
                              'parentAdminId': currentAdmin.id,
                              'permissions': permissionsMap,
                              'createdAt': DateTime.now().millisecondsSinceEpoch,
                              'updatedAt': DateTime.now().millisecondsSinceEpoch,
                            });
                          } else {
                            await usersRef.doc(existing.id).update({
                              'name': nameCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'permissions': permissionsMap,
                              'updatedAt': DateTime.now().millisecondsSinceEpoch,
                            });
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(existing == null ? 'Sub-Admin created successfully!' : 'Sub-Admin updated!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving sub-admin: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(existing == null ? 'Create Sub-Admin' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleSubAdminStatus(AdminAccountModel admin) async {
    final newStatus = admin.isActive ? 'suspended' : 'active';
    try {
      await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(admin.id).update({
        'status': newStatus,
        'isActive': newStatus == 'active' ? 1 : 0,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sub-admin "${admin.name}" marked as $newStatus'),
            backgroundColor: newStatus == 'active' ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AdminTheme.getCardBg(context);
    final textDark = AdminTheme.getTextDark(context);
    final textMuted = AdminTheme.getTextMuted(context);

    final auth = context.watch<AuthProvider>();
    final currentAdmin = auth.currentUser;
    final branchId = currentAdmin?.branchId;

    return Scaffold(
      backgroundColor: AdminTheme.getBackground(context),
      drawer: const AdminDrawer(currentRoute: '/admin/sub-admins'),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sub-Admin Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(
              'Branch: ${branchId ?? "All Branches"}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add Sub-Admin',
            onPressed: () => _openSubAdminDialog(),
          ),
        ],
      ),
      body: ResponsiveContainer.content(
        maxWidth: 1200,
        child: Column(
          children: [
            // Search & Add Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search sub-admins by name or email...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Sub-Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _openSubAdminDialog(),
                  ),
                ],
              ),
            ),

            // Live Stream of Sub-Admins belonging to this branch
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(FirestoreCollections.users)
                    .where('role', whereIn: ['admin', 'staff'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator(message: 'Loading sub-admins...');
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  var subAdmins = docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    data['id'] = d.id;
                    return AdminAccountModel.fromJson(data);
                  }).where((a) {
                    // Filter: must be sub-admin created under this branch or by this admin
                    final isCreatedByMe = a.parentAdminId != null && a.parentAdminId == currentAdmin?.id;
                    final isBranchStaff = a.isSubAdmin && a.branchId == branchId;
                    return isCreatedByMe || isBranchStaff;
                  }).toList();

                  final query = _searchCtrl.text.trim().toLowerCase();
                  if (query.isNotEmpty) {
                    subAdmins = subAdmins.where((a) =>
                        a.name.toLowerCase().contains(query) ||
                        a.email.toLowerCase().contains(query) ||
                        a.phone.toLowerCase().contains(query)).toList();
                  }

                  if (subAdmins.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.group_off_rounded,
                      title: 'No Sub-Admins Found',
                      description: 'Create restricted sub-admin accounts for your branch staff members.',
                      buttonText: 'Add Sub-Admin',
                      onButtonPressed: () => _openSubAdminDialog(),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: subAdmins.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final admin = subAdmins[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AdminTheme.primaryBlue.withValues(alpha: 0.12),
                                  child: Text(
                                    admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'S',
                                    style: const TextStyle(color: AdminTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        admin.name,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark),
                                      ),
                                      Text(
                                        '${admin.email} • ${admin.phone}',
                                        style: TextStyle(color: textMuted, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: admin.isActive ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    admin.status.toUpperCase(),
                                    style: TextStyle(
                                      color: admin.isActive ? AppColors.success : AppColors.error,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (action) {
                                    if (action == 'edit') {
                                      _openSubAdminDialog(existing: admin);
                                    } else if (action == 'toggle') {
                                      _toggleSubAdminStatus(admin);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_rounded, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit Restrictions'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Icon(admin.isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 18),
                                          const SizedBox(width: 8),
                                          Text(admin.isActive ? 'Suspend Account' : 'Activate Account'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),

                            // Permissions pills
                            Text(
                              'Allowed Actions:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _availablePermissions.map((p) {
                                final isAllowed = admin.permissions.contains(p['id']);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isAllowed
                                        ? AdminTheme.primaryBlue.withValues(alpha: 0.1)
                                        : (isDark ? Colors.white10 : Colors.grey.shade100),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isAllowed
                                          ? AdminTheme.primaryBlue.withValues(alpha: 0.3)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isAllowed ? Icons.check : Icons.lock_outline,
                                        size: 12,
                                        color: isAllowed ? AdminTheme.primaryBlue : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        p['label']!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isAllowed ? FontWeight.w600 : FontWeight.normal,
                                          color: isAllowed ? AdminTheme.primaryBlue : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
