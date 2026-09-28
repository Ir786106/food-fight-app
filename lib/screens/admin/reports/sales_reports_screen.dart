import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/providers/report_provider.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/widgets/admin/admin_drawer.dart';
import 'package:food_fight/widgets/admin/stat_card.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/network_image_view.dart';
import 'package:food_fight/widgets/common/error_view.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'package:food_fight/widgets/common/empty_state_view.dart';

class SalesReportsScreen extends StatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  State<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends State<SalesReportsScreen> {
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
          final rp = context.read<ReportProvider>();
          rp.setPreset(rp.selectedPreset, branchId: branchId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AdminTheme.getCardBg(context);
    final textDark = AdminTheme.getTextDark(context);
    final textMuted = AdminTheme.getTextMuted(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    final reportProvider = context.watch<ReportProvider>();
    final report = reportProvider.report;

    return Scaffold(
      backgroundColor: AdminTheme.getBackground(context),
      drawer: const AdminDrawer(currentRoute: '/admin/reports'),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sales & Analytics 📈', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(
              user?.branchId != null ? 'Branch: ${user!.branchId}' : 'All Branches (HQ)',
              style: const TextStyle(fontSize: 10.5, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'Custom Date Range',
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (range != null && context.mounted) {
                context.read<ReportProvider>().setCustomDateRange(range.start, range.end);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Report',
            onPressed: () => context.read<ReportProvider>().setPreset(reportProvider.selectedPreset),
          ),
        ],
      ),
      body: ResponsiveContainer.content(
        maxWidth: 1200,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip(context, 'today', 'Today', reportProvider),
                    _buildPresetChip(context, 'week', 'This Week', reportProvider),
                    _buildPresetChip(context, 'month', 'This Month', reportProvider),
                    _buildPresetChip(context, 'all', 'All Time', reportProvider),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (reportProvider.isLoading && report == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: LoadingIndicator(message: 'Generating sales report...'),
                )
              else if (reportProvider.errorMessage != null && report == null)
                ErrorView(
                  message: reportProvider.errorMessage!,
                  onRetry: () => reportProvider.setPreset(reportProvider.selectedPreset),
                )
              else if (report == null || report.totalOrders == 0)
                Material(
                  color: cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: EmptyStateView(
                      icon: Icons.bar_chart_rounded,
                      title: 'No Sales in Selected Period',
                      description: 'Orders placed during this time frame will be analyzed here.',
                    ),
                  ),
                )
              else ...[
                // KPI Metric Cards Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 400;
                    final isWide = constraints.maxWidth >= 720;
                    final crossAxisCount = isNarrow ? 1 : (isWide ? 4 : 2);

                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: 130,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      children: [
                        StatCard(
                          title: 'Total Revenue',
                          value: 'Rs. ${report.totalRevenue.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppColors.success,
                          subtitle: 'Gross Volume',
                        ),
                        StatCard(
                          title: 'Total Orders',
                          value: '${report.totalOrders}',
                          icon: Icons.receipt_long_rounded,
                          color: AdminTheme.secondaryBlue,
                          subtitle: '${report.deliveredOrders} Completed',
                        ),
                        StatCard(
                          title: 'Average Order Value',
                          value: 'Rs. ${report.averageOrderValue.toStringAsFixed(0)}',
                          icon: Icons.trending_up_rounded,
                          color: AppColors.primaryYellow,
                          subtitle: 'Per non-cancelled order',
                        ),
                        StatCard(
                          title: 'Order Status',
                          value: '${report.deliveredOrders} / ${report.cancelledOrders}',
                          icon: Icons.donut_large_rounded,
                          color: AppColors.accent,
                          subtitle: 'Delivered vs Cancelled',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Top Selling Items Section
                if (report.topSellingItems.isNotEmpty) ...[
                  Text(
                    'Best-Selling Menu Items 🔥',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: report.topSellingItems.take(5).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = report.topSellingItems[index];

                      return Material(
                        color: cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: NetworkImageView(
                                  imageUrl: item.imageUrl,
                                  width: 44,
                                  height: 44,
                                  fallbackIcon: Icons.fastfood_rounded,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: index == 0
                                        ? AppColors.warning
                                        : (index == 1 ? Colors.grey.shade600 : Colors.brown.shade400),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(6),
                                    ),
                                  ),
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${item.quantitySold} units sold',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                          trailing: Text(
                            'Rs. ${item.totalRevenue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AdminTheme.primaryBlue,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Daily Revenue Breakdown
                if (report.dailySales.isNotEmpty) ...[
                  Text(
                    'Daily Performance Breakdown 📅',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: report.dailySales.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final daily = report.dailySales[index];

                      return Material(
                        color: cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AdminTheme.primaryBlue.withValues(alpha: 0.1),
                            child: const Icon(Icons.calendar_today_rounded, color: AdminTheme.primaryBlue, size: 18),
                          ),
                          title: Text(
                            '${daily.date.day}/${daily.date.month}/${daily.date.year}',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textDark),
                          ),
                          subtitle: Text(
                            '${daily.ordersCount} orders',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                          trailing: Text(
                            'Rs. ${daily.revenue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.success,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    BuildContext context,
    String key,
    String label,
    ReportProvider provider,
  ) {
    final isSel = provider.selectedPreset == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSel,
        selectedColor: AdminTheme.primaryBlue,
        labelStyle: TextStyle(
          color: isSel ? Colors.white : Colors.grey.shade800,
          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
        ),
        onSelected: (val) {
          if (val) provider.setPreset(key);
        },
      ),
    );
  }
}
