import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/models/coupon_model.dart';
import 'package:food_fight/providers/coupon_provider.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/widgets/admin/admin_drawer.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/empty_state_view.dart';
import 'package:food_fight/widgets/common/error_view.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'package:food_fight/core/utils/validator_utils.dart';

class ManageCouponsScreen extends StatefulWidget {
  const ManageCouponsScreen({super.key});

  @override
  State<ManageCouponsScreen> createState() => _ManageCouponsScreenState();
}

class _ManageCouponsScreenState extends State<ManageCouponsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _lastBranchId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final branchId = auth.currentUser?.branchId;
    if (_lastBranchId != branchId) {
      _lastBranchId = branchId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<CouponProvider>().watchCoupons(branchId: branchId);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openCouponDialog({CouponModel? coupon}) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: coupon?.code ?? '');
    String selectedType = coupon?.type ?? 'percentage';
    final valueCtrl = TextEditingController(
      text: coupon != null ? coupon.value.toStringAsFixed(0) : '15',
    );
    final minOrderCtrl = TextEditingController(
      text: coupon != null ? coupon.minimumOrder.toStringAsFixed(0) : '500',
    );
    final maxDiscCtrl = TextEditingController(
      text: coupon?.maximumDiscount != null ? coupon!.maximumDiscount!.toStringAsFixed(0) : '300',
    );
    final descCtrl = TextEditingController(text: coupon?.description ?? '');
    int validDays = 30;
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
              coupon == null ? 'Create Coupon' : 'Edit Coupon',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Coupon code'),
                      decoration: InputDecoration(
                        labelText: 'Promo Code *',
                        hintText: 'e.g. FIGHT50, BURGER20',
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Discount Type',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AdminTheme.getTextDark(dialogContext),
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
                          value: selectedType,
                          items: const [
                            DropdownMenuItem(value: 'percentage', child: Text('Percentage Discount (%)')),
                            DropdownMenuItem(value: 'flat', child: Text('Flat Amount (Rs.)')),
                            DropdownMenuItem(value: 'free_delivery', child: Text('Free Delivery')),
                          ],
                          onChanged: (val) => setDialogState(() => selectedType = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (selectedType != 'free_delivery') ...[
                      TextFormField(
                        controller: valueCtrl,
                        keyboardType: TextInputType.number,
                        validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Discount value'),
                        decoration: InputDecoration(
                          labelText: selectedType == 'percentage'
                              ? 'Discount % (e.g. 20)'
                              : 'Flat Discount Rs. (e.g. 200)',
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (selectedType == 'percentage') ...[
                      TextFormField(
                        controller: maxDiscCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Max Discount Cap Rs. (optional)',
                          hintText: 'e.g. 300',
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextFormField(
                      controller: minOrderCtrl,
                      keyboardType: TextInputType.number,
                      validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Minimum order'),
                      decoration: InputDecoration(
                        labelText: 'Minimum Order Requirement (Rs.)',
                        hintText: 'e.g. 500',
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description / Terms',
                        hintText: 'e.g. Get 20% off on all burgers above Rs. 500',
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Text(
                          'Valid for:',
                          style: TextStyle(fontSize: 13, color: AdminTheme.getTextMuted(dialogContext)),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: validDays,
                          items: const [
                            DropdownMenuItem(value: 7, child: Text('7 Days')),
                            DropdownMenuItem(value: 15, child: Text('15 Days')),
                            DropdownMenuItem(value: 30, child: Text('30 Days')),
                            DropdownMenuItem(value: 60, child: Text('60 Days')),
                            DropdownMenuItem(value: 90, child: Text('90 Days')),
                            DropdownMenuItem(value: 365, child: Text('1 Year')),
                          ],
                          onChanged: (v) => setDialogState(() => validDays = v!),
                        ),
                      ],
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
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        final code = codeCtrl.text.trim().toUpperCase();
                        final val = double.tryParse(valueCtrl.text.trim()) ?? 0.0;
                        final minOrder = double.tryParse(minOrderCtrl.text.trim()) ?? 0.0;
                        final maxDisc = double.tryParse(maxDiscCtrl.text.trim());

                        setDialogState(() => isSaving = true);
                        try {
                          final provider = context.read<CouponProvider>();
                          final currentBranchId = context.read<AuthProvider>().currentUser?.branchId;

                          if (coupon == null) {
                            await provider.createCoupon(CouponModel(
                              id: '',
                              code: code,
                              description: descCtrl.text.trim(),
                              type: selectedType,
                              value: val,
                              minimumOrder: minOrder,
                              maximumDiscount: maxDisc,
                              validFrom: DateTime.now(),
                              validUntil: DateTime.now().add(Duration(days: validDays)),
                              isActive: true,
                              branchId: currentBranchId,
                            ));
                          } else {
                            await provider.updateCoupon(CouponModel(
                              id: coupon.id,
                              code: code,
                              description: descCtrl.text.trim(),
                              type: selectedType,
                              value: val,
                              minimumOrder: minOrder,
                              maximumDiscount: maxDisc,
                              validFrom: coupon.validFrom,
                              validUntil: DateTime.now().add(Duration(days: validDays)),
                              isActive: coupon.isActive,
                              usageCount: coupon.usageCount,
                              usageLimit: coupon.usageLimit,
                              branchId: coupon.branchId ?? currentBranchId,
                            ));
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
                    : Text(coupon == null ? 'Create' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(CouponModel coupon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.getCardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Coupon'),
        content: Text('Are you sure you want to permanently delete "${coupon.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<CouponProvider>().deleteCoupon(coupon.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Coupon "${coupon.code}" deleted')),
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
      drawer: const AdminDrawer(currentRoute: '/admin/coupons'),
      appBar: AppBar(
        title: const Text('Manage Coupons & Deals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create Coupon',
            onPressed: () => _openCouponDialog(),
          ),
        ],
      ),
      body: Consumer<CouponProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.coupons.isEmpty) {
            return const LoadingIndicator(message: 'Loading active promo deals...');
          }

          if (provider.errorMessage != null && provider.coupons.isEmpty) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.fetchCoupons(),
            );
          }

          final query = _searchCtrl.text.trim().toLowerCase();
          final filteredCoupons = provider.coupons.where((c) {
            return query.isEmpty ||
                c.code.toLowerCase().contains(query) ||
                (c.description?.toLowerCase().contains(query) ?? false);
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
                            hintText: 'Search promo codes...',
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
                        onPressed: () => _openCouponDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Coupon', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // Coupons List
                Expanded(
                  child: filteredCoupons.isEmpty
                      ? EmptyStateView(
                          icon: Icons.local_offer_rounded,
                          title: provider.coupons.isEmpty ? 'No Coupons Created' : 'No Matching Coupons',
                          description: provider.coupons.isEmpty
                              ? 'Create promo codes and discounts to boost order conversions.'
                              : 'Try searching with another keyword.',
                          buttonText: provider.coupons.isEmpty ? 'Create First Coupon' : null,
                          onButtonPressed: provider.coupons.isEmpty ? () => _openCouponDialog() : null,
                        )
                      : RefreshIndicator(
                          onRefresh: () => provider.fetchCoupons(),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredCoupons.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final coupon = filteredCoupons[index];
                              final isExpired = DateTime.now().isAfter(coupon.validUntil);

                              return Material(
                                color: cardBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
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
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AdminTheme.primaryBlue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AdminTheme.primaryBlue.withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Text(
                                              coupon.code,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                                letterSpacing: 1.2,
                                                color: AdminTheme.primaryBlue,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Switch(
                                                value: coupon.isActive && !isExpired,
                                                activeThumbColor: AdminTheme.primaryBlue,
                                                onChanged: isExpired
                                                    ? null
                                                    : (val) => provider.toggleActive(coupon.id, coupon.isActive),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: Icon(Icons.more_vert_rounded, color: textMuted),
                                                onSelected: (val) {
                                                  if (val == 'edit') {
                                                    _openCouponDialog(coupon: coupon);
                                                  } else if (val == 'delete') {
                                                    _confirmDelete(coupon);
                                                  }
                                                },
                                                itemBuilder: (_) => [
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit_rounded, size: 18, color: AppColors.darkBrown),
                                                        SizedBox(width: 8),
                                                        Text('Edit'),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
                                                        SizedBox(width: 8),
                                                        Text('Delete', style: TextStyle(color: AppColors.error)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (coupon.description?.isNotEmpty == true)
                                        Text(
                                          coupon.description!,
                                          style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 4,
                                        children: [
                                          _buildBadge(
                                            label: coupon.type == 'percentage'
                                                ? '${coupon.value.toStringAsFixed(0)}% OFF'
                                                : (coupon.type == 'free_delivery'
                                                    ? 'FREE DELIVERY'
                                                    : 'Rs. ${coupon.value.toStringAsFixed(0)} OFF'),
                                            color: AppColors.success,
                                          ),
                                          _buildBadge(
                                            label: 'Min Rs. ${coupon.minimumOrder.toStringAsFixed(0)}',
                                            color: AppColors.darkBrown,
                                          ),
                                          if (isExpired)
                                            _buildBadge(label: 'EXPIRED', color: AppColors.error)
                                          else
                                            _buildBadge(
                                              label: 'Expires ${_formatDate(coupon.validUntil)}',
                                              color: AppColors.warning,
                                            ),
                                          _buildBadge(
                                            label: '${coupon.usageCount} Used',
                                            color: AppColors.darkBrown,
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
        onPressed: () => _openCouponDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Coupon'),
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
