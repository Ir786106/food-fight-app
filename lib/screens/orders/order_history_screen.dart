import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/status_badge.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/responsive_layout.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _watchedCustomerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null && user.id != _watchedCustomerId) {
      _watchedCustomerId = user.id;
      context.read<OrderProvider>().watchCustomerOrders(user.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getProgressStep(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.accepted:
        return 1;
      case OrderStatus.preparing:
      case OrderStatus.ready:
        return 2;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[dt.month - 1];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$m ${dt.day}, ${dt.year} • $hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final customerId = auth.currentUser?.id ?? '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Orders 🥊'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              tabs: const [
                Tab(text: 'Current Orders'),
                Tab(text: 'Past Orders'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer.content(
          maxWidth: 860,
          child: customerId.isEmpty
              ? EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  title: 'Please Sign In',
                  description: 'Log in to your account to view your active deliveries and order history.',
                  buttonText: 'Log In Now',
                  onButtonPressed: () => Navigator.of(context).pushNamed('/login'),
                )
              : Builder(
                  builder: (context) {
                    if (orderProvider.isLoading && orderProvider.customerOrders.isEmpty) {
                      return const LoadingIndicator(message: 'Loading your orders...');
                    }

                    if (orderProvider.errorMessage != null && orderProvider.customerOrders.isEmpty) {
                      return ErrorView(
                        message: orderProvider.errorMessage!,
                        onRetry: () => orderProvider.watchCustomerOrders(customerId),
                      );
                    }

                    final allOrders = orderProvider.customerOrders;

                    final currentOrders = allOrders.where((o) =>
                        o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).toList();

                    final pastOrders = allOrders.where((o) =>
                        o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled).toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Current Orders with Horizontal Progress Indicator
                        RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async => orderProvider.watchCustomerOrders(customerId),
                          child: currentOrders.isEmpty
                              ? ListView(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 80),
                                      child: EmptyStateView(
                                        icon: Icons.delivery_dining_outlined,
                                        title: 'No Active Orders',
                                        description: 'You have no orders currently in preparation or delivery.',
                                        buttonText: 'Order Food Now',
                                        onButtonPressed: () =>
                                            Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: currentOrders.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final order = currentOrders[index];
                                    final step = _getProgressStep(order.status);

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () => Navigator.of(context).pushNamed(
                                            '/order-tracking',
                                            arguments: order,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(18),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Header row: Order number & Status badge
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      order.orderNumber,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 16,
                                                        color: colorScheme.onSurface,
                                                      ),
                                                    ),
                                                    StatusBadge(status: order.status.name),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${order.items.length} items • ${order.restaurantName}',
                                                  style: TextStyle(
                                                    color: colorScheme.onSurfaceVariant,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),

                                                // Horizontal Progress Indicator matching status timeline (Spec benchmark)
                                                _buildHorizontalProgress(step, colorScheme),
                                                const SizedBox(height: 16),

                                                Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                                                const SizedBox(height: 12),

                                                // Bottom row: Total & Track Button
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Total',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: colorScheme.onSurfaceVariant,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Rs. ${order.total.toStringAsFixed(0)}',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w900,
                                                            fontSize: 16,
                                                            color: AppColors.primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                        minimumSize: const Size(0, 36),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      ),
                                                      onPressed: () => Navigator.of(context).pushNamed(
                                                        '/order-tracking',
                                                        arguments: order,
                                                      ),
                                                      icon: const Icon(Icons.location_searching_rounded, size: 14),
                                                      label: const Text('Track Live', style: TextStyle(fontSize: 12.5)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        // Tab 2: Past Orders (items, total, date, and delivered/cancelled status)
                        RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async => orderProvider.watchCustomerOrders(customerId),
                          child: pastOrders.isEmpty
                              ? ListView(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 80),
                                      child: EmptyStateView(
                                        icon: Icons.history_rounded,
                                        title: 'No Past Orders',
                                        description: 'Your completed and past meal battles will show up here.',
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: pastOrders.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final order = pastOrders[index];

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () => Navigator.of(context).pushNamed(
                                            '/order-tracking',
                                            arguments: order,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(18),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Header row: ID, Date & Status
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      order.orderNumber,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 15.5,
                                                        color: colorScheme.onSurface,
                                                      ),
                                                    ),
                                                    StatusBadge(status: order.status.name),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _formatDate(order.createdAt),
                                                  style: TextStyle(
                                                    color: colorScheme.onSurfaceVariant,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),

                                                // Items summary
                                                Text(
                                                  order.items.map((i) => '${i.quantity}x ${i.food.name}').join(', '),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: colorScheme.onSurface.withValues(alpha: 0.9),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                                                const SizedBox(height: 12),

                                                // Bottom row: Total & Reorder Action
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Total: Rs. ${order.total.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 15.5,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'View Details',
                                                          style: TextStyle(
                                                            color: colorScheme.onSurface,
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 12.5,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colorScheme.onSurface),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildHorizontalProgress(int currentStep, ColorScheme colorScheme) {
    const steps = ['Confirmed', 'Preparing', 'On the Way', 'Delivered'];

    return Column(
      children: [
        Row(
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Line connector
              final stepIndex = i ~/ 2;
              final isPassed = currentStep > stepIndex + 1;
              return Expanded(
                child: Container(
                  height: 3,
                  color: isPassed ? AppColors.primary : colorScheme.surfaceContainerHighest,
                ),
              );
            } else {
              // Circle node
              final stepIndex = i ~/ 2;
              final isPassed = currentStep > stepIndex;
              final isCurrent = currentStep == stepIndex + 1;

              return Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPassed
                      ? AppColors.primary
                      : (isCurrent ? AppColors.primary : colorScheme.surfaceContainerHighest),
                  border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: isPassed && !isCurrent
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              );
            }
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.map((s) {
            return Text(
              s,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
