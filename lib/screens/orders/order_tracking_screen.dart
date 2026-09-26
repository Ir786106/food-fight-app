import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/status_badge.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../widgets/common/empty_state_view.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  OrderModel? _initialOrder;
  bool _initialized = false;

  static const List<Map<String, dynamic>> _trackingSteps = [
    {
      'title': 'Order Confirmed',
      'desc': 'Kitchen received and confirmed order',
      'icon': Icons.receipt_long_rounded,
      'status': OrderStatus.pending,
    },
    {
      'title': 'Preparing',
      'desc': 'Chefs are cooking fresh food for you',
      'icon': Icons.soup_kitchen_rounded,
      'status': OrderStatus.preparing,
    },
    {
      'title': 'Ready',
      'desc': 'Hot food packed and ready for dispatch',
      'icon': Icons.inventory_2_rounded,
      'status': OrderStatus.ready,
    },
    {
      'title': 'Rider Assigned',
      'desc': 'Delivery champion assigned to your order',
      'icon': Icons.person_pin_circle_rounded,
      'status': OrderStatus.assigned,
    },
    {
      'title': 'Out for Delivery',
      'desc': 'Rider is on the way to your location',
      'icon': Icons.delivery_dining_rounded,
      'status': OrderStatus.outForDelivery,
    },
    {
      'title': 'Delivered',
      'desc': 'Enjoy your meal! Fight your hunger!',
      'icon': Icons.check_circle_rounded,
      'status': OrderStatus.delivered,
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is OrderModel) {
        _initialOrder = args;
        context.read<OrderProvider>().watchOrder(args.id);
      }
      _initialized = true;
    }
  }

  int _getStatusStepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.accepted:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.ready:
        return 2;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
        return 3;
      case OrderStatus.outForDelivery:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = (orderProvider.currentOrder != null && orderProvider.currentOrder!.id == _initialOrder?.id)
        ? orderProvider.currentOrder!
        : _initialOrder;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Live Tracking')),
        body: const Center(
          child: EmptyStateView(
            icon: Icons.receipt_long_rounded,
            title: 'Order Not Found',
            description: 'Unable to load live tracking information for this order.',
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isCancelled = order.status == OrderStatus.cancelled;
    final currentStepIndex = _getStatusStepIndex(order.status);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${order.orderNumber} Live Tracking'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(child: StatusBadge(status: order.status.name)),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer.content(
          maxWidth: 860,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCancelled
                          ? [Colors.red.shade900, Colors.red.shade700]
                          : [AppColors.primary, const Color(0xFFFF5722)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isCancelled ? Colors.red : AppColors.primary).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCancelled ? '❌ Order Cancelled' : '🥊 Live Status: ${order.statusLabel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isCancelled
                            ? (order.cancellationReason?.isNotEmpty == true
                                ? 'Reason: ${order.cancellationReason}'
                                : 'This order was cancelled.')
                            : 'Estimated Delivery in 25-35 minutes',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Status Timeline
                Text(
                  'Order Journey',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                if (isCancelled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_rounded, color: Colors.red, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            order.cancellationReason?.isNotEmpty == true
                                ? 'Order was cancelled: "${order.cancellationReason}"'
                                : 'This order has been cancelled.',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: List.generate(_trackingSteps.length, (index) {
                      final step = _trackingSteps[index];
                      final isCompleted = currentStepIndex > index;
                      final isCurrent = currentStepIndex == index;
                      final isPending = currentStepIndex < index;
                      final isLast = index == _trackingSteps.length - 1;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step Indicator & connecting line
                          Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppColors.primary
                                      : (isCompleted ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200)),
                                  shape: BoxShape.circle,
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  step['icon'] as IconData,
                                  size: 18,
                                  color: (isCurrent || isCompleted) ? Colors.white : Colors.grey.shade500,
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2.5,
                                  height: 40,
                                  color: isCompleted ? Colors.green : (isDark ? Colors.white12 : Colors.grey.shade300),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),

                          // Text details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        step['title'] as String,
                                        style: TextStyle(
                                          fontWeight: (isCurrent || isCompleted) ? FontWeight.w800 : FontWeight.w500,
                                          fontSize: 15,
                                          color: isPending
                                              ? colorScheme.onSurface.withValues(alpha: 0.5)
                                              : colorScheme.onSurface,
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'IN PROGRESS',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    step['desc'] as String,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),

                const SizedBox(height: 12),

                // Delivery Destination Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.deliveryAddress,
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Order Receipt Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items Summary (${order.items.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantity}x  ${item.food.name}${item.selectedSize != null ? " (${item.selectedSize})" : ""}',
                                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
