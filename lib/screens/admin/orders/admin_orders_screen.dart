import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/providers/order_provider.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/widgets/admin/admin_drawer.dart';
import 'package:food_fight/widgets/admin/status_badge.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/empty_state_view.dart';
import 'package:food_fight/widgets/common/error_view.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'order_detail_modal.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Map<String, String>> _tabs = [
    {'title': 'All', 'status': 'all'},
    {'title': 'Pending', 'status': 'pending'},
    {'title': 'Accepted', 'status': 'accepted'},
    {'title': 'Preparing', 'status': 'preparing'},
    {'title': 'Ready', 'status': 'ready'},
    {'title': 'Out for Delivery', 'status': 'outForDelivery'},
    {'title': 'Delivered', 'status': 'delivered'},
    {'title': 'Cancelled', 'status': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().watchAdminOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AdminTheme.getBackground(context),
      drawer: const AdminDrawer(currentRoute: '/admin/orders'),
      appBar: AppBar(
        title: const Text(
          'Order Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Orders',
            onPressed: () => context.read<OrderProvider>().watchAdminOrders(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((t) {
            final statusKey = t['status']!;
            int count = 0;
            switch (statusKey) {
              case 'all':
                count = orderProvider.allCount;
                break;
              case 'pending':
                count = orderProvider.pendingCount;
                break;
              case 'preparing':
                count = orderProvider.preparingCount;
                break;
              case 'ready':
                count = orderProvider.readyCount;
                break;
              case 'outForDelivery':
                count = orderProvider.outForDeliveryCount;
                break;
              case 'delivered':
                count = orderProvider.deliveredCount;
                break;
              case 'cancelled':
                count = orderProvider.cancelledCount;
                break;
              default:
                count = orderProvider.adminOrders.where((o) => o.status.name.toLowerCase() == statusKey.toLowerCase()).length;
                break;
            }

            return Tab(
              child: Row(
                children: [
                  Text(t['title']!),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((t) => _OrdersTabList(status: t['status']!)).toList(),
      ),
    );
  }
}

class _OrdersTabList extends StatelessWidget {
  final String status;

  const _OrdersTabList({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AdminTheme.getCardBg(context);
    final textDark = AdminTheme.getTextDark(context);
    final textMuted = AdminTheme.getTextMuted(context);

    final orderProvider = context.watch<OrderProvider>();

    if (orderProvider.isLoading && orderProvider.adminOrders.isEmpty) {
      return const LoadingIndicator(message: 'Loading orders...');
    }

    if (orderProvider.errorMessage != null && orderProvider.adminOrders.isEmpty) {
      return ErrorView(
        message: orderProvider.errorMessage!,
        onRetry: () => context.read<OrderProvider>().watchAdminOrders(),
      );
    }

    final allOrders = orderProvider.adminOrders;
    final orders = status == 'all'
        ? allOrders
        : allOrders.where((o) {
            final orderStatus = o.status.name.toLowerCase();
            final targetStatus = status.toLowerCase();
            return orderStatus == targetStatus;
          }).toList();

    if (orders.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_rounded,
        title: 'No Orders In This Tab',
        description: status == 'all'
            ? 'Incoming customer orders will appear here in real-time.'
            : 'No orders currently matching "$status" status.',
      );
    }

    return ResponsiveContainer.content(
      maxWidth: 1200,
      child: RefreshIndicator(
        onRefresh: () async => context.read<OrderProvider>().watchAdminOrders(),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];

            return Material(
              color: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => OrderDetailModal(order: order),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Order Number + Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AdminTheme.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt_rounded, color: AdminTheme.primaryBlue, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                order.orderNumber,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                          StatusBadge(status: order.status.name),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Customer Info & Address
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.customerName.isNotEmpty ? order.customerName : 'Customer',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatDate(order.createdAt),
                            style: TextStyle(color: textMuted, fontSize: 11.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.deliveryAddress,
                              style: TextStyle(color: textMuted, fontSize: 12.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      // Items summary and Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${order.items.length} ${order.items.length == 1 ? "item" : "items"} • ${order.paymentMethod.toUpperCase()}',
                            style: TextStyle(color: textMuted, fontSize: 12.5, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Rs. ${order.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AdminTheme.primaryBlue,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
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

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}
