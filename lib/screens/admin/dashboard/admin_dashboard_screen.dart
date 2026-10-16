import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/widgets/admin/admin_scaffold.dart';
import 'package:food_fight/widgets/admin/stat_card.dart';
import 'package:food_fight/widgets/admin/status_badge.dart';
import 'package:food_fight/providers/admin_dashboard_provider.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/providers/branch_provider.dart';
import 'package:food_fight/providers/chat_provider.dart';
import 'package:food_fight/screens/admin/orders/order_detail_modal.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/error_view.dart';
import 'package:food_fight/widgets/common/empty_state_view.dart';
import 'package:food_fight/widgets/common/network_image_view.dart';
import 'package:food_fight/widgets/charts/order_status_donut_chart.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _initialized = false;
  String? _lastBranchId;
  String _timePeriod = 'today'; // 'today', 'week', 'month'
  String? _selectedBranchId; // For Super Admin override

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final branchId = _selectedBranchId ?? auth.currentUser?.branchId;
    if (!_initialized || _lastBranchId != branchId) {
      _initialized = true;
      _lastBranchId = branchId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AdminDashboardProvider>().watchDashboardData(branchId: branchId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = AdminTheme.getTextDark(context);
    final textMuted = AdminTheme.getTextMuted(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Exit App?'),
            content: const Text('Are you sure you want to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AdminTheme.primaryBlue),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: AdminScaffold(
        currentRoute: '/admin/dashboard',
        backgroundColor: AdminTheme.getBackground(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Admin Portal',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _selectedBranchId != null
                  ? 'Branch: $_selectedBranchId'
                  : (user?.branchId != null ? 'Branch: ${user!.branchId}' : 'All Branches (HQ)'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Dashboard',
            onPressed: () => context.read<AdminDashboardProvider>().refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.storefront_rounded),
            tooltip: 'Customer View',
            onPressed: () => Navigator.of(context).pushNamed('/home'),
          ),
        ],
      ),
      body: Consumer<AdminDashboardProvider>(
        builder: (context, dashboard, _) {
          if (dashboard.isLoading && dashboard.recentOrders.isEmpty) {
            return const LoadingIndicator(message: 'Loading live restaurant metrics...');
          }

          if (dashboard.errorMessage != null && dashboard.recentOrders.isEmpty) {
            return ErrorView(
              message: dashboard.errorMessage!,
              onRetry: () => dashboard.refresh(),
            );
          }

          final isSuperAdmin = user?.isSuperAdmin == true || user?.role == 'super_admin';
          final branches = context.watch<BranchProvider>().branches;

          return RefreshIndicator(
            onRefresh: () => dashboard.refresh(),
            child: ResponsiveContainer.content(
              maxWidth: 1200,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dashboard Overview',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                ),
                              ),
                              Text(
                                'Real-time sales, order pipeline & operations',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.success.withValues(alpha: isDark ? 0.4 : 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Kitchen Live',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Controls: Time Period Toggle & Super Admin Branch Selector
                    Row(
                      children: [
                        // Period Selector: Today / Week / Month
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPeriodButton('Today', 'today', isDark),
                              _buildPeriodButton('Week', 'week', isDark),
                              _buildPeriodButton('Month', 'month', isDark),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (isSuperAdmin && branches.isNotEmpty)
                          Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E28) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white12 : Colors.grey.shade300,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _selectedBranchId,
                                hint: const Text('All Branches (HQ)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                                icon: const Icon(Icons.arrow_drop_down, size: 18),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('All Branches (HQ)'),
                                  ),
                                  ...branches.map((b) => DropdownMenuItem<String?>(
                                    value: b.id,
                                    child: Text(b.name),
                                  )),
                                ],
                                onChanged: (bId) {
                                  setState(() => _selectedBranchId = bId);
                                  context.read<AdminDashboardProvider>().watchDashboardData(branchId: bId);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Primary Sales & Order Summary (Responsive Grid)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 400;
                        final isWide = constraints.maxWidth >= 720;
                        final unreadChats = context.watch<ChatProvider>().totalAdminUnread;

                        // Dynamically resolve sales and subtitle by selected time period
                        final revenueTitle = _timePeriod == 'today'
                            ? "Today's Revenue"
                            : (_timePeriod == 'week' ? "Weekly Revenue" : "Monthly Revenue");
                        final revenueVal = _timePeriod == 'today'
                            ? dashboard.todaySales
                            : (_timePeriod == 'week' ? dashboard.weeklySales : dashboard.monthlySales);
                        final revenueSubtitle = _timePeriod == 'today'
                            ? '${dashboard.todayOrdersCount} Orders'
                            : (_timePeriod == 'week' ? 'Last 7 Days' : 'Last 30 Days');

                        return GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: isNarrow ? 1.9 : (isWide ? 1.6 : 1.4),
                          ),
                          children: [
                            StatCard(
                              title: revenueTitle,
                              value: 'Rs. ${revenueVal.toStringAsFixed(0)}',
                              icon: Icons.monetization_on_rounded,
                              color: AppColors.success,
                              subtitle: revenueSubtitle,
                              onTap: () => Navigator.of(context).pushNamed('/admin/reports'),
                            ),
                            StatCard(
                              title: "Today's Orders",
                              value: '${dashboard.todayOrdersCount}',
                              icon: Icons.receipt_long_rounded,
                              color: AdminTheme.secondaryBlue,
                              subtitle: '${dashboard.completedOrdersCount} Delivered',
                              onTap: () => Navigator.of(context).pushNamed('/admin/orders'),
                            ),
                            StatCard(
                              title: 'Active Riders',
                              value: '${dashboard.activeRidersCount}',
                              icon: Icons.two_wheeler_rounded,
                              color: AppColors.primaryYellow,
                              subtitle: 'Online Fleet',
                              onTap: () => Navigator.of(context).pushNamed('/admin/delivery-areas'),
                            ),
                            StatCard(
                              title: 'New Customers',
                              value: '${dashboard.newCustomersCount}',
                              icon: Icons.people_alt_rounded,
                              color: AppColors.accent,
                              subtitle: 'Active Registered',
                              onTap: () => Navigator.of(context).pushNamed('/admin/customers'),
                            ),
                            StatCard(
                              title: 'Unread Chats',
                              value: '$unreadChats',
                              icon: Icons.chat_rounded,
                              color: AppColors.brandMaroon,
                              subtitle: unreadChats > 0 ? 'Requires Attention' : 'All Inquiries Addressed',
                              onTap: () => Navigator.of(context).pushNamed('/admin/chats'),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Order Pipeline Status Bar (Live counts by state)
                    Text(
                      'Live Order Pipeline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
                            maxCrossAxisExtent: 170,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: isWide ? 1.65 : 1.4,
                          ),
                          children: [
                            _buildPipelineTile(
                              context: context,
                              label: 'Pending',
                              count: dashboard.pendingOrdersCount,
                              color: AdminTheme.statusPending,
                              icon: Icons.hourglass_top_rounded,
                            ),
                            _buildPipelineTile(
                              context: context,
                              label: 'Preparing',
                              count: dashboard.preparingOrdersCount,
                              color: AdminTheme.statusPreparing,
                              icon: Icons.soup_kitchen_rounded,
                            ),
                            _buildPipelineTile(
                              context: context,
                              label: 'Ready',
                              count: dashboard.readyOrdersCount,
                              color: AdminTheme.statusReady,
                              icon: Icons.done_all_rounded,
                            ),
                            _buildPipelineTile(
                              context: context,
                              label: 'On the Way',
                              count: dashboard.outForDeliveryOrdersCount,
                              color: AdminTheme.statusOutForDelivery,
                              icon: Icons.moped_rounded,
                            ),
                            _buildPipelineTile(
                              context: context,
                              label: 'Delivered',
                              count: dashboard.completedOrdersCount,
                              color: AdminTheme.statusDelivered,
                              icon: Icons.check_circle_rounded,
                            ),
                            _buildPipelineTile(
                              context: context,
                              label: 'Cancelled',
                              count: dashboard.cancelledOrdersCount,
                              color: AdminTheme.statusCancelled,
                              icon: Icons.cancel_rounded,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Live Order Fulfillment Distribution Chart (fl_chart)
                    if ((dashboard.completedOrdersCount +
                            dashboard.pendingOrdersCount +
                            dashboard.preparingOrdersCount +
                            dashboard.readyOrdersCount +
                            dashboard.outForDeliveryOrdersCount +
                            dashboard.cancelledOrdersCount) > 0) ...[
                      OrderStatusDonutChart(
                        deliveredCount: dashboard.completedOrdersCount,
                        pendingCount: dashboard.pendingOrdersCount +
                            dashboard.preparingOrdersCount +
                            dashboard.readyOrdersCount +
                            dashboard.outForDeliveryOrdersCount,
                        cancelledCount: dashboard.cancelledOrdersCount,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Management Shortcuts
                    Text(
                      'Management Shortcuts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionBtn(
                            context: context,
                            title: 'Add Menu Item',
                            icon: Icons.add_box_rounded,
                            color: Colors.deepOrange,
                            onTap: () => Navigator.of(context).pushNamed('/admin/menu/add'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionBtn(
                            context: context,
                            title: 'Manage Orders',
                            icon: Icons.list_alt_rounded,
                            color: AdminTheme.primaryBlue,
                            onTap: () => Navigator.of(context).pushNamed('/admin/orders'),
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
                            title: 'Categories',
                            icon: Icons.category_rounded,
                            color: AppColors.primaryYellow,
                            onTap: () => Navigator.of(context).pushNamed('/admin/categories'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionBtn(
                            context: context,
                            title: 'Coupons & Deals',
                            icon: Icons.local_offer_rounded,
                            color: AppColors.primaryDark,
                            onTap: () => Navigator.of(context).pushNamed('/admin/coupons'),
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
                            title: 'Delivery Zones',
                            icon: Icons.map_rounded,
                            color: AppColors.accent,
                            onTap: () => Navigator.of(context).pushNamed('/admin/delivery-areas'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionBtn(
                            context: context,
                            title: 'Sales & Reports',
                            icon: Icons.analytics_rounded,
                            color: AdminTheme.primaryBlue,
                            onTap: () => Navigator.of(context).pushNamed('/admin/reports'),
                          ),
                        ),
                      ],
                    ),

                    // Popular Items Section
                    if (dashboard.popularItems.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Popular Kitchen Items',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed('/admin/menu'),
                            child: const Text('View All Menu'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: dashboard.popularItems.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = dashboard.popularItems[index];
                            final cardBg = AdminTheme.getCardBg(context);
                            final borderColor = isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade200;

                            return Container(
                              width: 220,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: NetworkImageView(
                                      imageUrl: item.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fallbackIcon: Icons.fastfood_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rs. ${item.finalPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: AdminTheme.primaryBlue,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                                            const SizedBox(width: 2),
                                            Text(
                                              item.rating.toStringAsFixed(1),
                                              style: TextStyle(color: textMuted, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Live Order Stream
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Live Order Stream',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushNamed('/admin/orders'),
                          child: const Text('View All Orders'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (dashboard.recentOrders.isEmpty)
                      Material(
                        color: AdminTheme.getCardBg(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: EmptyStateView(
                            icon: Icons.inbox_rounded,
                            title: 'No Orders Placed Yet',
                            description: 'Incoming customer orders will appear here in real-time.',
                          ),
                        ),
                      )
                    else
                      Column(
                        children: dashboard.recentOrders.take(6).map((order) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: AdminTheme.getCardBg(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: CircleAvatar(
                                  backgroundColor: AdminTheme.primaryBlue.withValues(alpha: 0.1),
                                  child: const Icon(Icons.receipt_rounded, color: AdminTheme.primaryBlue, size: 20),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        order.orderNumber,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                          color: textDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(status: order.status.name, isSmall: true),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${order.items.length} ${order.items.length == 1 ? "item" : "items"} • Rs. ${order.total.toStringAsFixed(0)} • ${order.customerName}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: textMuted, fontSize: 12.5),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _timeAgo(order.createdAt),
                                        style: TextStyle(color: textMuted.withValues(alpha: 0.7), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  if (MediaQuery.sizeOf(context).width >= 600) {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(24),
                                            child: OrderDetailModal(order: order),
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                      ),
                                      builder: (_) => OrderDetailModal(order: order),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        }).toList(),
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

  Widget _buildPeriodButton(String label, String period, bool isDark) {
    final isSelected = _timePeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _timePeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AdminTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildPipelineTile({
    required BuildContext context,
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AdminTheme.getCardBg(context);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/admin/orders'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AdminTheme.getTextMuted(context),
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
    final cardBg = AdminTheme.getCardBg(context);
    final textDark = AdminTheme.getTextDark(context);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
