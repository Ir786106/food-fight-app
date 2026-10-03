import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/validator_utils.dart';
import '../../../models/rider_model.dart';
import '../../../providers/rider_provider.dart';
import '../../../widgets/admin/admin_drawer.dart';
import '../../../widgets/common/empty_state_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../widgets/common/responsive_layout.dart';

class ManageRidersScreen extends StatefulWidget {
  const ManageRidersScreen({super.key});

  @override
  State<ManageRidersScreen> createState() => _ManageRidersScreenState();
}

class _ManageRidersScreenState extends State<ManageRidersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      context.read<RiderProvider>().watchAllRiders();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddEditRiderModal({RiderModel? rider}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: rider?.name ?? '');
    final emailCtrl = TextEditingController(text: rider?.email ?? '');
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: rider?.phone ?? '');
    final vehicleTypeCtrl = TextEditingController(text: rider?.vehicleType ?? 'Motorcycle');
    final vehicleNumberCtrl = TextEditingController(text: rider?.vehicleNumber ?? '');
    bool obscurePassword = true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setModalState) {
          return AlertDialog(
            backgroundColor: AdminTheme.getCardBg(dialogContext),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  rider == null ? Icons.person_add_rounded : Icons.edit_rounded,
                  color: AdminTheme.primaryBlue,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  rider == null ? 'Register New Delivery Rider' : 'Edit Rider Profile',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rider == null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AdminTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminTheme.primaryBlue.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18, color: AdminTheme.primaryBlue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'A login account will be automatically generated with this email and password.',
                                style: TextStyle(fontSize: 11.5, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextFormField(
                      controller: nameCtrl,
                      validator: (v) => ValidatorUtils.validateRequired(v, fieldName: 'Full Name'),
                      decoration: const InputDecoration(
                        labelText: 'Rider Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      enabled: rider == null,
                      keyboardType: TextInputType.emailAddress,
                      validator: ValidatorUtils.validateEmail,
                      decoration: InputDecoration(
                        labelText: 'Login Email Address *',
                        hintText: 'e.g. rider1@foodfight.pk',
                        prefixIcon: const Icon(Icons.email_outlined),
                        helperText: rider == null ? 'Rider will use this to sign in' : null,
                      ),
                    ),
                    if (rider == null) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Assign Login Password *',
                          hintText: 'Min. 6 characters',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                          ),
                          helperText: 'Temporary or initial password for rider',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.length < 10) ? 'Valid phone required' : null,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone *',
                        hintText: '0300 1234567',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: vehicleTypeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Type (e.g. Motorcycle, Scooter)',
                        prefixIcon: Icon(Icons.two_wheeler_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: vehicleNumberCtrl,
                      decoration: const InputDecoration(
                        labelText: 'License Plate (e.g. LEA-24-1234)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AdminTheme.primaryBlue),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setModalState(() => isSaving = true);

                        final riderProv = context.read<RiderProvider>();
                        bool ok;
                        if (rider == null) {
                          ok = await riderProv.createRiderWithAuth(
                            name: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim().toLowerCase(),
                            password: passwordCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            vehicleType: vehicleTypeCtrl.text.trim(),
                            vehicleNumber: vehicleNumberCtrl.text.trim(),
                          );
                        } else {
                          final updatedRider = RiderModel(
                            id: rider.id,
                            userId: rider.userId,
                            name: nameCtrl.text.trim(),
                            email: rider.email ?? emailCtrl.text.trim().toLowerCase(),
                            phone: phoneCtrl.text.trim(),
                            vehicleType: vehicleTypeCtrl.text.trim(),
                            vehicleNumber: vehicleNumberCtrl.text.trim(),
                            isActive: rider.isActive,
                            isOnline: rider.isOnline,
                            rating: rider.rating,
                            totalDeliveries: rider.totalDeliveries,
                            createdAt: rider.createdAt,
                            updatedAt: DateTime.now(),
                          );
                          ok = await riderProv.updateRider(updatedRider);
                        }

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          final err = riderProv.errorMessage;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? (rider == null
                                      ? 'Rider registered! Login Email: ${emailCtrl.text.trim()}'
                                      : 'Rider profile updated!')
                                  : (err ?? 'Failed to register rider')),
                              backgroundColor: ok ? AppColors.success : AppColors.error,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(rider == null ? 'Register Rider' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riderProvider = context.watch<RiderProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AdminTheme.getCardBg(context);

    final riders = riderProvider.riders.where((r) {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) ||
          r.phone.toLowerCase().contains(q) ||
          (r.vehicleNumber?.toLowerCase().contains(q) ?? false);
    }).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: AdminTheme.getBackground(context),
        drawer: const AdminDrawer(currentRoute: '/admin/riders'),
        appBar: AppBar(
          title: const Text(
            'Delivery Riders Fleet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: AdminTheme.primaryBlue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.two_wheeler_rounded),
              tooltip: 'Open Rider Console',
              onPressed: () => Navigator.pushNamed(context, '/rider/dashboard'),
            ),
            IconButton(
              icon: const Icon(Icons.person_add_rounded),
              tooltip: 'Register Rider',
              onPressed: () => _showAddEditRiderModal(),
            ),
          ],
        ),
        body: ResponsiveContainer.content(
          maxWidth: 1140,
          child: Column(
            children: [
              // Search & Fleet Summary Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search rider by name, phone, or plate...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white12 : Colors.grey.shade300,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminTheme.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onPressed: () => _showAddEditRiderModal(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Rider'),
                    ),
                  ],
                ),
              ),

              // Rider List Content
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (riderProvider.isLoading && riderProvider.riders.isEmpty) {
                      return const Center(child: LoadingIndicator(message: 'Loading rider fleet...'));
                    }

                    if (riderProvider.errorMessage != null && riderProvider.riders.isEmpty) {
                      return Center(
                        child: ErrorView(
                          message: riderProvider.errorMessage!,
                          onRetry: () => riderProvider.watchAllRiders(),
                        ),
                      );
                    }

                    if (riders.isEmpty) {
                      return const Center(
                        child: EmptyStateView(
                          icon: Icons.two_wheeler_rounded,
                          title: 'No Riders Registered',
                          description: 'Add your restaurant delivery champions to start assigning orders.',
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 780;

                        if (isDesktop) {
                          // Grid Layout for Tablet/Desktop
                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 440,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 2.3,
                            ),
                            itemCount: riders.length,
                            itemBuilder: (ctx, i) => _buildRiderCard(context, riders[i]),
                          );
                        }

                        // Mobile Stacked List
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: riders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => _buildRiderCard(context, riders[i]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiderCard(BuildContext context, RiderModel rider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AdminTheme.getCardBg(context);
    final textDark = AdminTheme.getTextDark(context);
    final textMuted = AdminTheme.getTextMuted(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rider.isOnline
              ? AppColors.success.withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: rider.isOnline ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: rider.isOnline
                ? AppColors.success.withValues(alpha: 0.15)
                : AdminTheme.primaryBlue.withValues(alpha: 0.12),
            child: Icon(
              Icons.two_wheeler_rounded,
              color: rider.isOnline ? AppColors.success : AdminTheme.primaryBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rider.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: rider.isOnline
                            ? AppColors.success.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rider.isOnline ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: rider.isOnline ? AppColors.success : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${rider.phone} • ${rider.vehicleType ?? "Bike"}${rider.vehicleNumber != null ? " (${rider.vehicleNumber})" : ""}',
                  style: TextStyle(fontSize: 12, color: textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (rider.email != null && rider.email!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 12.5, color: AdminTheme.primaryBlue.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rider.email!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.brandYellow : AdminTheme.primaryBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                    const SizedBox(width: 3),
                    Text(
                      rider.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.local_shipping_outlined, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${rider.totalDeliveries} Deliveries',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'edit') {
                _showAddEditRiderModal(rider: rider);
              } else if (val == 'toggle_active') {
                context.read<RiderProvider>().toggleActive(rider.id, !rider.isActive);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Rider'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_active',
                child: Row(
                  children: [
                    Icon(
                      rider.isActive ? Icons.cancel_outlined : Icons.check_circle_outline,
                      color: rider.isActive ? AppColors.error : AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rider.isActive ? 'Deactivate' : 'Activate',
                      style: TextStyle(color: rider.isActive ? AppColors.error : AppColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
