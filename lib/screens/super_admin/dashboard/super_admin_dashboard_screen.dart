import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/core/theme/super_admin_theme.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:food_fight/widgets/super_admin/super_admin_drawer.dart';
import 'package:food_fight/widgets/admin/stat_card.dart';
import 'package:food_fight/providers/super_admin_provider.dart';
import 'package:food_fight/providers/branch_provider.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/error_view.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textDark = SuperAdminTheme.getTextDark(context);

    final provider = context.watch<SuperAdminProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }
        final shouldSwitch = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit Super Admin HQ?'),
            content: const Text('Do you want to return to the Customer Storefront?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: SuperAdminTheme.primary),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Go to Storefront'),
              ),
            ],
          ),
        );
        if (shouldSwitch == true && context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
        }
      },
      child: Scaffold(
        backgroundColor: SuperAdminTheme.getBackground(context),
        drawer: const SuperAdminDrawer(currentRoute: '/super-admin/dashboard'),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: SuperAdminTheme.accentGold, size: 20),
            SizedBox(width: 8),
            Text(
              'Super Admin HQ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: SuperAdminTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Metrics',
            onPressed: () => context.read<SuperAdminProvider>().loadMetrics(),
          ),
          IconButton(
            icon: const Icon(Icons.storefront_rounded),
            tooltip: 'Restaurant Admin Panel',
            onPressed: () => Navigator.of(context).pushNamed('/admin/dashboard'),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading && provider.totalOrders == 0) {
            return const LoadingIndicator(message: 'Compiling platform-wide intelligence...');
          }

          if (provider.errorMessage != null && provider.totalOrders == 0) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.loadMetrics(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadMetrics(),
            child: ResponsiveContainer.content(
              maxWidth: 1200,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System Status Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            SuperAdminTheme.primary,
                            Color(0xFF230833),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: SuperAdminTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: SuperAdminTheme.accentGold.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: SuperAdminTheme.accentGold, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Global System Operational ⚡',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Platform Revenue: Rs. ${provider.platformRevenue.toStringAsFixed(0)} • Store Open',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // User Accounts & Fleet Grid
                    Text(
                      'Platform Accounts & Fleet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 720;

                        return GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: isWide ? 1.75 : 1.5,
                          ),
                          children: [
                            StatCard(
                              title: 'Admin Accounts',
                              value: '${provider.totalAdmins}',
                              icon: Icons.admin_panel_settings_rounded,
                              color: SuperAdminTheme.primary,
                              subtitle: 'Active Managers',
                              onTap: () => Navigator.of(context).pushNamed('/super-admin/admins'),
                            ),
                            StatCard(
                              title: 'Kitchen Staff',
                              value: '${provider.totalStaff}',
                              icon: Icons.soup_kitchen_rounded,
                              color: AppColors.darkBrown,
                              subtitle: 'Operational Crew',
                              onTap: () => Navigator.of(context).pushNamed('/super-admin/admins'),
                            ),
                            StatCard(
                              title: 'Delivery Riders',
                              value: '${provider.totalRiders}',
                              icon: Icons.two_wheeler_rounded,
                              color: AppColors.primaryYellow,
                              subtitle: 'Courier Fleet',
                              onTap: () => Navigator.of(context).pushNamed('/admin/delivery-areas'),
                            ),
                            StatCard(
                              title: 'Customers',
                              value: '${provider.totalCustomers}',
                              icon: Icons.people_alt_rounded,
                              color: AppColors.accent,
                              subtitle: 'Registered Foodies',
                              onTap: () => Navigator.of(context).pushNamed('/admin/customers'),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Platform Order Volume Grid
                    Text(
                      'Platform Order Lifecycle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 720;

                        return GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: isWide ? 1.75 : 1.5,
                          ),
                          children: [
                            StatCard(
                              title: 'Total Orders',
                              value: '${provider.totalOrders}',
                              icon: Icons.receipt_long_rounded,
                              color: SuperAdminTheme.primary,
                              subtitle: 'Lifetime Volume',
                              onTap: () => Navigator.of(context).pushNamed('/admin/orders'),
                            ),
                            StatCard(
                              title: 'Delivered Orders',
                              value: '${provider.completedOrders}',
                              icon: Icons.check_circle_rounded,
                              color: AppColors.success,
                              subtitle: 'Successful Dispatches',
                              onTap: () => Navigator.of(context).pushNamed('/admin/orders'),
                            ),
                            StatCard(
                              title: 'Cancelled Orders',
                              value: '${provider.cancelledOrders}',
                              icon: Icons.cancel_rounded,
                              color: AppColors.error,
                              subtitle: 'Refunded / Aborted',
                              onTap: () => Navigator.of(context).pushNamed('/admin/orders'),
                            ),
                            StatCard(
                              title: 'Restaurants',
                              value: '${provider.totalRestaurants}',
                              icon: Icons.store_rounded,
                              color: SuperAdminTheme.accentGold,
                              subtitle: 'Food Fight HQ Branch',
                              onTap: () => Navigator.of(context).pushNamed('/super-admin/settings'),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // =========================================================
                    // Multi-Branch Performance & Financial Comparison (P&L)
                    // =========================================================
                    Consumer<BranchProvider>(
                      builder: (context, branchProvider, _) {
                        return _buildBranchPerformanceSection(
                          context: context,
                          branchProvider: branchProvider,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                          textDark: textDark,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Quick Management Actions
                    Text(
                      'Super Admin Quick Controls',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionBtn(
                            context: context,
                            title: 'Manage Admins',
                            icon: Icons.manage_accounts_rounded,
                            color: SuperAdminTheme.primary,
                            onTap: () => Navigator.of(context).pushNamed('/super-admin/admins'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionBtn(
                            context: context,
                            title: 'System Settings',
                            icon: Icons.tune_rounded,
                            color: AppColors.darkBrown,
                            onTap: () => Navigator.of(context).pushNamed('/super-admin/settings'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionBtn(
                            context: context,
                            title: 'Audit Logs',
                            icon: Icons.policy_rounded,
                            color: AppColors.primaryYellow,
                            onTap: () => Navigator.of(context).pushNamed('/super-admin/audit'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionBtn(
                            context: context,
                            title: 'Branch Portal',
                            icon: Icons.dashboard_customize_rounded,
                            color: AppColors.accent,
                            onTap: () => Navigator.of(context).pushNamed('/admin/dashboard'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildBranchPerformanceSection({
    required BuildContext context,
    required BranchProvider branchProvider,
    required bool isDark,
    required Color textDark,
  }) {
    final branches = branchProvider.sortedBranches;
    final cardBg = SuperAdminTheme.getCardBg(context);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200;
    final textMuted = SuperAdminTheme.getTextMuted(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with sorting options
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Branch Performance & P&L 📊',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                Text(
                  'Real-time financial comparison across restaurant locations',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: SuperAdminTheme.primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.add_location_alt_rounded, size: 16),
              label: const Text('Add Branch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pushNamed('/super-admin/admins'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Sort Selector Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text('Sort by: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
              const SizedBox(width: 8),
              _buildSortChip(
                label: 'Revenue',
                icon: Icons.monetization_on_rounded,
                isSelected: branchProvider.selectedSort == BranchSortOption.revenue,
                onTap: () => branchProvider.setSortOption(BranchSortOption.revenue),
                context: context,
              ),
              const SizedBox(width: 8),
              _buildSortChip(
                label: 'Profit / Loss',
                icon: Icons.trending_up_rounded,
                isSelected: branchProvider.selectedSort == BranchSortOption.profit,
                onTap: () => branchProvider.setSortOption(BranchSortOption.profit),
                context: context,
              ),
              const SizedBox(width: 8),
              _buildSortChip(
                label: 'Order Volume',
                icon: Icons.receipt_long_rounded,
                isSelected: branchProvider.selectedSort == BranchSortOption.orderCount,
                onTap: () => branchProvider.setSortOption(BranchSortOption.orderCount),
                context: context,
              ),
              const SizedBox(width: 8),
              _buildSortChip(
                label: 'Branch Name',
                icon: Icons.sort_by_alpha_rounded,
                isSelected: branchProvider.selectedSort == BranchSortOption.name,
                onTap: () => branchProvider.setSortOption(BranchSortOption.name),
                context: context,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Aggregate Financial Overview Strip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SuperAdminTheme.primary.withValues(alpha: isDark ? 0.25 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SuperAdminTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCol('Active Branches', '${branchProvider.branches.length}', textDark, textMuted),
              _buildMetricCol('Total Revenue', 'Rs. ${branchProvider.totalPlatformRevenue.toStringAsFixed(0)}', AppColors.success, textMuted),
              _buildMetricCol('Total Expenses', 'Rs. ${branchProvider.totalPlatformExpenses.toStringAsFixed(0)}', AppColors.warning, textMuted),
              _buildMetricCol(
                'Net Profit',
                'Rs. ${branchProvider.totalPlatformProfit.toStringAsFixed(0)}',
                branchProvider.totalPlatformProfit >= 0 ? AppColors.success : AppColors.error,
                textMuted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Branch Comparison Cards List
        if (branches.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Text('No branches available.', style: TextStyle(color: textMuted)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: branches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final branch = branches[index];
              final isTopPerformer = index == 0;
              final isProfitable = branch.profit >= 0;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isTopPerformer
                        ? SuperAdminTheme.accentGold.withValues(alpha: 0.5)
                        : borderColor,
                    width: isTopPerformer ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isTopPerformer
                                ? SuperAdminTheme.accentGold.withValues(alpha: 0.2)
                                : (isDark ? Colors.white10 : Colors.grey.shade200),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: isTopPerformer ? SuperAdminTheme.accentGold : textMuted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      branch.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isTopPerformer) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: SuperAdminTheme.accentGold.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.emoji_events_rounded, color: SuperAdminTheme.accentGold, size: 12),
                                          SizedBox(width: 3),
                                          Text(
                                            'Top',
                                            style: TextStyle(color: SuperAdminTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                '${branch.address}, ${branch.city}',
                                style: TextStyle(color: textMuted, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: branch.isActive ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            branch.status.toUpperCase(),
                            style: TextStyle(
                              color: branch.isActive ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Financial metrics row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Revenue', style: TextStyle(fontSize: 11, color: textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              'Rs. ${branch.revenue.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.success),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Orders', style: TextStyle(fontSize: 11, color: textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              '${branch.orderCount}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textDark),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expenses', style: TextStyle(fontSize: 11, color: textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              'Rs. ${branch.expenses.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.warning),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Net Profit / Loss', style: TextStyle(fontSize: 11, color: textMuted)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isProfitable
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${isProfitable ? '+' : ''}Rs. ${branch.profit.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: isProfitable ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMetricCol(String label, String value, Color valColor, Color textMuted) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: valColor)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10.5, color: textMuted)),
      ],
    );
  }

  Widget _buildSortChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? SuperAdminTheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? SuperAdminTheme.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : SuperAdminTheme.getTextDark(context)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : SuperAdminTheme.getTextDark(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = SuperAdminTheme.getCardBg(context);
    final textDark = SuperAdminTheme.getTextDark(context);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
