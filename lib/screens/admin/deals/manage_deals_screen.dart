import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/deal_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/deal_provider.dart';
import '../../../providers/menu_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/admin/admin_scaffold.dart';
import 'add_edit_deal_dialog.dart';

class ManageDealsScreen extends StatefulWidget {
  const ManageDealsScreen({super.key});

  @override
  State<ManageDealsScreen> createState() => _ManageDealsScreenState();
}

class _ManageDealsScreenState extends State<ManageDealsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final branchId = auth.currentUser?.branchId;
      context.read<DealProvider>().watchDeals(branchId: branchId);
      context.read<MenuProvider>().watchMenuItems(branchId: branchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dealProvider = context.watch<DealProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final deals = dealProvider.deals;

    return AdminScaffold(
      currentRoute: '/admin/deals',
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Branch Deals & Combos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Deals',
            onPressed: () {
              final branchId = context.read<AuthProvider>().currentUser?.branchId;
              dealProvider.watchDeals(branchId: branchId);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandYellow,
        foregroundColor: AppColors.onYellow,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Deal', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openAddEditDialog(context),
      ),
      body: dealProvider.isLoading && deals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : deals.isEmpty
              ? _buildEmptyState(context)
              : _buildDealsList(context, deals, isDark, colorScheme),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.brandYellow.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                size: 64,
                color: AppColors.brandYellow,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Deals Created Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create special combos, meal platters, or percentage discounts for your branch.\nThey will show up automatically on customer apps.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandYellow,
                foregroundColor: AppColors.onYellow,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Deal', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _openAddEditDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealsList(
    BuildContext context,
    List<DealModel> deals,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isWide ? 420 : 600,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: isWide ? 1.35 : 1.25,
          ),
          itemCount: deals.length,
          itemBuilder: (ctx, index) {
            final deal = deals[index];
            return _buildDealCard(context, deal, isDark, colorScheme);
          },
        );
      },
    );
  }

  Widget _buildDealCard(
    BuildContext context,
    DealModel deal,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final dealProvider = context.read<DealProvider>();
    final isValid = deal.isValidNow;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2128) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isValid
              ? AppColors.brandYellow.withValues(alpha: 0.6)
              : Colors.grey.withValues(alpha: 0.2),
          width: isValid ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with status & actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isValid
                        ? AppColors.success.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isValid ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                        size: 13,
                        color: isValid ? AppColors.success : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isValid ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          color: isValid ? AppColors.success : Colors.grey,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (deal.branchId != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      deal.branchId!,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onYellow,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Switch(
                  value: deal.isActive,
                  activeThumbColor: AppColors.brandYellow,
                  onChanged: (val) => dealProvider.toggleStatus(deal.id, val),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openAddEditDialog(context, deal: deal);
                    } else if (val == 'delete') {
                      _confirmDelete(context, deal);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Deal'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete Deal', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deal.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (deal.bundleItems.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: deal.bundleItems.take(3).map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.quantity}x ${item.name}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rs. ${deal.dealPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.success,
                        ),
                      ),
                      if (deal.originalPrice > deal.dealPrice) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Rs. ${deal.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${deal.savingsPercentage.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandYellow,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddEditDialog(BuildContext context, {DealModel? deal}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditDealDialog(deal: deal),
    );
  }

  void _confirmDelete(BuildContext ctx, DealModel deal) async {
    final messenger = ScaffoldMessenger.of(ctx);
    final provider = ctx.read<DealProvider>();
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Deal'),
        content: Text('Are you sure you want to permanently remove "${deal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.deleteDeal(deal.id);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Deal "${deal.title}" deleted')),
        );
      }
    }
  }
}
