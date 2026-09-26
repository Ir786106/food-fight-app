import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/models/delivery_area_model.dart';
import 'package:food_fight/providers/delivery_area_provider.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/widgets/admin/admin_drawer.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/empty_state_view.dart';
import 'package:food_fight/widgets/common/error_view.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'package:food_fight/core/utils/validator_utils.dart';

class ManageDeliveryAreasScreen extends StatefulWidget {
  const ManageDeliveryAreasScreen({super.key});

  @override
  State<ManageDeliveryAreasScreen> createState() => _ManageDeliveryAreasScreenState();
}

class _ManageDeliveryAreasScreenState extends State<ManageDeliveryAreasScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAreaDialog({DeliveryAreaModel? area}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: area?.name ?? '');
    final chargeCtrl = TextEditingController(
      text: area != null ? area.deliveryCharge.toStringAsFixed(0) : '150',
    );
    final descCtrl = TextEditingController(text: area?.description ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: AdminTheme.getCardBg(dialogContext),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              area == null ? 'Add Delivery Zone' : 'Edit Delivery Zone',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AdminTheme.getTextDark(dialogContext),
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Zone name'),
                      decoration: InputDecoration(
                        labelText: 'Area / Zone Name *',
                        hintText: 'e.g. DHA Phase 5, Gulberg, Blue Area',
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: chargeCtrl,
                      keyboardType: TextInputType.number,
                      validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Delivery charge'),
                      decoration: InputDecoration(
                        labelText: 'Delivery Charge (Rs.) *',
                        hintText: '150',
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Description / Estimated Time (optional)',
                        hintText: 'Estimated 30-45 mins delivery',
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        final name = nameCtrl.text.trim();
                        final charge = double.tryParse(chargeCtrl.text.trim()) ?? 0.0;

                        setDialogState(() => isSaving = true);
                        try {
                          final provider = context.read<DeliveryAreaProvider>();

                          if (area == null) {
                            await provider.createArea(DeliveryAreaModel(
                              id: '',
                              name: name,
                              deliveryCharge: charge,
                              description: descCtrl.text.trim(),
                              isActive: true,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ));
                          } else {
                            await provider.updateArea(DeliveryAreaModel(
                              id: area.id,
                              name: name,
                              deliveryCharge: charge,
                              description: descCtrl.text.trim(),
                              isActive: area.isActive,
                              createdAt: area.createdAt,
                              updatedAt: DateTime.now(),
                            ));
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
                    : Text(area == null ? 'Create Zone' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(DeliveryAreaModel area) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.getCardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Delivery Zone'),
        content: Text('Are you sure you want to remove the delivery zone "${area.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<DeliveryAreaProvider>().deleteArea(area.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Zone "${area.name}" deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AdminTheme.getCardBg(context);
    final textDark = AdminTheme.getTextDark(context);
    final textMuted = AdminTheme.getTextMuted(context);

    return Scaffold(
      backgroundColor: AdminTheme.getBackground(context),
      drawer: const AdminDrawer(currentRoute: '/admin/delivery-areas'),
      appBar: AppBar(
        title: const Text('Delivery Zones & Charges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Zone',
            onPressed: () => _openAreaDialog(),
          ),
        ],
      ),
      body: Consumer<DeliveryAreaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.areas.isEmpty) {
            return const LoadingIndicator(message: 'Loading delivery coverage zones...');
          }

          if (provider.errorMessage != null && provider.areas.isEmpty) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.fetchAreas(),
            );
          }

          final query = _searchCtrl.text.trim().toLowerCase();
          final filteredAreas = provider.areas.where((a) {
            return query.isEmpty ||
                a.name.toLowerCase().contains(query) ||
                (a.description?.toLowerCase().contains(query) ?? false);
          }).toList();

          return ResponsiveContainer.content(
            maxWidth: 1200,
            child: Column(
              children: [
                // Top Search and Add Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search delivery zones...',
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
                          backgroundColor: AdminTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _openAreaDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Zone', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // Zones List
                Expanded(
                  child: filteredAreas.isEmpty
                      ? EmptyStateView(
                          icon: Icons.map_rounded,
                          title: provider.areas.isEmpty ? 'No Delivery Zones Configured' : 'No Matching Zones',
                          description: provider.areas.isEmpty
                              ? 'Add service zones with customized delivery charges.'
                              : 'Try searching with another keyword.',
                          buttonText: provider.areas.isEmpty ? 'Add Zone' : null,
                          onButtonPressed: provider.areas.isEmpty ? () => _openAreaDialog() : null,
                        )
                      : RefreshIndicator(
                          onRefresh: () => provider.fetchAreas(),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredAreas.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final area = filteredAreas[index];

                              return Material(
                                color: cardBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: AdminTheme.primaryBlue.withValues(alpha: 0.1),
                                    child: const Icon(Icons.location_on_rounded, color: AdminTheme.primaryBlue, size: 22),
                                  ),
                                  title: Text(
                                    area.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: textDark,
                                    ),
                                  ),
                                  subtitle: Text(
                                    area.description?.isNotEmpty == true
                                        ? '${area.description} • Fee: Rs. ${area.deliveryCharge.toStringAsFixed(0)}'
                                        : 'Standard Fee: Rs. ${area.deliveryCharge.toStringAsFixed(0)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: textMuted, fontSize: 12.5),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: area.isActive,
                                        activeThumbColor: AdminTheme.primaryBlue,
                                        onChanged: (val) => provider.toggleActive(area.id, area.isActive),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert_rounded, color: textMuted),
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            _openAreaDialog(area: area);
                                          } else if (val == 'delete') {
                                            _confirmDelete(area);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => _openAreaDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Zone'),
      ),
    );
  }
}
