import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/status_badge.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_view.dart';
import '../../core/responsive/responsive.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/skeleton/order_card_skeleton.dart';
import '../../widgets/orders/order_speed_dial_fab.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_colors.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  OrderModel? _selectedOrder;
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
        return 1;
      case OrderStatus.accepted:
        return 2;
      case OrderStatus.preparing:
      case OrderStatus.ready:
        return 3;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return 4;
      case OrderStatus.delivered:
        return 5;
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
      floatingActionButton: const OrderSpeedDialFab(),
      appBar: AppBar(
        title: const Text('My Orders'),
        elevation: 0,
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProv, _) {
              final unread = chatProv.totalUnreadForCustomer;
              return IconButton(
                tooltip: 'Support Chat',
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(
                    '$unread',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  backgroundColor: AppColors.brandMaroon,
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.brandMaroon),
                ),
                onPressed: () => Navigator.pushNamed(context, '/chat'),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
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
                color: AppColors.brandYellow,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandYellow.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: AppColors.onYellow,
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
        child: customerId.isEmpty
            ? ResponsiveBox.form(
                maxWidth: 500,
                child: EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  title: 'Please Sign In',
                  description: 'Log in to your account to view your active deliveries and order history.',
                  buttonText: 'Log In Now',
                  onButtonPressed: () => Navigator.of(context).pushNamed('/login'),
                ),
              )
            : Builder(
                  builder: (context) {
                    if (orderProvider.isLoading && orderProvider.customerOrders.isEmpty) {
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, AppDimens.navBarScrollPadding),
                        itemCount: 4,
                        itemBuilder: (_, __) => const OrderCardSkeleton(),
                      );
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

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 840;
                        final activeOrder = _selectedOrder ??
                            (currentOrders.isNotEmpty
                                ? currentOrders.first
                                : (pastOrders.isNotEmpty ? pastOrders.first : null));

                        final ordersView = TabBarView(
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
                                  padding: const EdgeInsets.fromLTRB(20, 20, 20, AppDimens.navBarScrollPadding),
                                  itemCount: currentOrders.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final order = currentOrders[index];
                                    final step = _getProgressStep(order.status);

                                    final isSelected = isWide && activeOrder?.id == order.id;

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected ? AppColors.brandYellow : Colors.transparent,
                                          width: 2,
                                        ),
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
                                          onTap: () {
                                            if (isWide) {
                                              setState(() => _selectedOrder = order);
                                            } else {
                                              Navigator.of(context).pushNamed(
                                                '/order-tracking',
                                                arguments: order,
                                              );
                                            }
                                          },
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
                                                  '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'} • ${order.restaurantName}',
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
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w900,
                                                            fontSize: 16,
                                                            color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: AppColors.brandYellow,
                                                        foregroundColor: AppColors.onYellow,
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
                                                      label: const Text('Track Live', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
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
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.only(top: 80),
                                      child: EmptyStateView(
                                        icon: Icons.history_rounded,
                                        title: 'No Past Orders',
                                        description: 'Your completed and past meal battles will show up here.',
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(20, 20, 20, AppDimens.navBarScrollPadding),
                                  itemCount: pastOrders.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final order = pastOrders[index];

                                    final isSelected = isWide && activeOrder?.id == order.id;

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected ? AppColors.brandYellow : Colors.transparent,
                                          width: 2,
                                        ),
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
                                          onTap: () {
                                            if (isWide) {
                                              setState(() => _selectedOrder = order);
                                            } else {
                                              Navigator.of(context).pushNamed(
                                                '/order-tracking',
                                                arguments: order,
                                              );
                                            }
                                          },
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
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 15.5,
                                                        color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        FilledButton.icon(
                                                          style: FilledButton.styleFrom(
                                                            backgroundColor: AppColors.primaryYellow,
                                                            foregroundColor: AppColors.brandMaroon,
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                            minimumSize: Size.zero,
                                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                          ),
                                                          onPressed: () => _reorder(context, order),
                                                          icon: const Icon(Icons.replay_rounded, size: 13),
                                                          label: const Text(
                                                            'Reorder',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          'Details',
                                                          style: TextStyle(
                                                            color: colorScheme.onSurfaceVariant,
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 2),
                                                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: colorScheme.onSurfaceVariant),
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

                    if (isWide) {
                      return ResponsiveBox(
                        maxWidth: 1240,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: ordersView,
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 7,
                                child: _buildOrderDetailPane(activeOrder, colorScheme, isDark),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ResponsiveBox.form(
                      child: ordersView,
                    );
                  },
                );
              },
            ),
      ),
    );
  }

  Widget _buildHorizontalProgress(int currentStep, ColorScheme colorScheme) {
    const steps = ['Pending', 'Confirmed', 'Preparing', 'On the Way', 'Delivered'];

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
                      ? AppColors.brandYellow
                      : (isCurrent ? AppColors.brandYellow : colorScheme.surfaceContainerHighest),
                  border: isCurrent ? Border.all(color: AppColors.brandMaroon, width: 2) : null,
                ),
                child: isPassed && !isCurrent
                    ? const Icon(Icons.check, size: 12, color: AppColors.onYellow)
                    : null,
              );
            }
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.map((s) {
            return Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _reorder(BuildContext context, OrderModel order) {
    final cart = context.read<CartProvider>();
    if (order.branchId != null && order.branchId!.isNotEmpty) {
      cart.setBranchId(order.branchId);
    }
    for (var item in order.items) {
      cart.addToCart(
        item.food,
        quantity: item.quantity,
        note: item.note,
        selectedSize: item.selectedSize,
        selectedVariant: item.selectedVariant,
        selectedAddons: item.selectedAddons,
      );
    }
    final itemCount = order.items.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $itemCount ${itemCount == 1 ? "item" : "items"} from ${order.orderNumber} to cart!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).pushNamed('/cart'),
        ),
      ),
    );
  }

  Widget _buildOrderDetailPane(OrderModel? order, ColorScheme colorScheme, bool isDark) {
    if (order == null) {
      return Container(
        height: 380,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Select an order to view live details',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final step = _getProgressStep(order.status);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.createdAt),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                StatusBadge(status: order.status.name),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.deliveryAddress,
                      style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Delivery Progress',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildHorizontalProgress(step, colorScheme),
            const SizedBox(height: 20),
            Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Ordered Items (${order.items.length})',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.brandMaroon),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.food.name,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: colorScheme.onSurface),
                      ),
                    ),
                    Text(
                      'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Paid', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface)),
                Text(
                  'Rs. ${order.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Live Map Tracking',
                    icon: Icons.map_rounded,
                    onPressed: () => Navigator.of(context).pushNamed(
                      '/order-tracking',
                      arguments: order,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _reorder(context, order),
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text('Reorder', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

