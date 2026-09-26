import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/status_badge.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/orders/live_tracking_map_widget.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  OrderModel? _initialOrder;
  bool _initialized = false;
  bool _isCancelling = false;

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

  void _showCancellationDialog(BuildContext context, OrderModel order) {
    String selectedReason = 'Ordered by mistake';
    final otherCtrl = TextEditingController();

    const reasons = [
      'Ordered by mistake',
      'Changed my mind',
      'Delivery address needs change',
      'Taking longer than expected',
      'Other reason',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final theme = Theme.of(sheetContext);
          final colorScheme = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Cancel Food Order',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Are you sure you want to cancel ${order.orderNumber}? Please tell us why:',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  ...reasons.map((r) => RadioListTile<String>(
                        value: r,
                        groupValue: selectedReason,
                        title: Text(r, style: const TextStyle(fontSize: 13.5)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: Colors.red,
                        onChanged: (val) => setModalState(() => selectedReason = val!),
                      )),
                  if (selectedReason == 'Other reason') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: otherCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Please specify reason *',
                        hintText: 'e.g. Need to reorder items',
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Keep Order'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: _isCancelling
                              ? null
                              : () async {
                                  final finalReason = selectedReason == 'Other reason'
                                      ? otherCtrl.text.trim()
                                      : selectedReason;

                                  setState(() => _isCancelling = true);
                                  Navigator.pop(ctx);

                                  final ok = await context.read<OrderProvider>().updateOrderStatus(
                                        order.id,
                                        OrderStatus.cancelled,
                                        cancellationReason: finalReason,
                                      );

                                  if (mounted) {
                                    setState(() => _isCancelling = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(ok
                                            ? 'Order cancelled successfully.'
                                            : 'Could not cancel order. Cancellation window may have expired.'),
                                        backgroundColor: ok ? Colors.red : Colors.orange,
                                      ),
                                    );
                                  }
                                },
                          child: const Text('Confirm Cancel'),
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
    );
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
    final isCancelled = order.status == OrderStatus.cancelled;
    final isDelivered = order.status == OrderStatus.delivered;
    final currentStepIndex = _getStatusStepIndex(order.status);

    // Calculate cancellation window (10 minutes default configurable)
    const int cancellationWindowMinutes = 10;
    final elapsedMinutes = DateTime.now().difference(order.createdAt).inMinutes;
    final remainingMinutes = cancellationWindowMinutes - elapsedMinutes;
    final canCancel = !isCancelled &&
        !isDelivered &&
        (order.status == OrderStatus.pending || order.status == OrderStatus.accepted) &&
        remainingMinutes > 0;
    final windowExpired = !isCancelled &&
        !isDelivered &&
        (order.status == OrderStatus.pending || order.status == OrderStatus.accepted) &&
        remainingMinutes <= 0;

    return PopScope(
      canPop: true,
      child: Scaffold(
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
                            : (isDelivered
                                ? [Colors.green.shade800, Colors.green.shade600]
                                : [AppColors.primary, const Color(0xFFFF5722)]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isCancelled
                                  ? Colors.red
                                  : (isDelivered ? Colors.green : AppColors.primary))
                              .withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCancelled
                              ? '❌ Order Cancelled'
                              : (isDelivered ? '✅ Order Delivered' : '🥊 Live Status: ${order.statusLabel}'),
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
                              : (isDelivered
                                  ? 'Thank you for ordering with Food Fight!'
                                  : 'Estimated Delivery in 25-35 minutes'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Real-time GPS Rider Location Map
                  if (!isCancelled) ...[
                    LiveTrackingMapWidget(
                      orderId: order.id,
                      deliveryAddress: order.deliveryAddress,
                      isOutForDelivery: order.status == OrderStatus.outForDelivery,
                    ),
                    const SizedBox(height: 24),
                  ],

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

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? Colors.green
                                        : (isCurrent
                                            ? AppColors.primary
                                            : colorScheme.surfaceContainerHighest),
                                    shape: BoxShape.circle,
                                    border: isCurrent
                                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 3)
                                        : null,
                                  ),
                                  child: Icon(
                                    step['icon'] as IconData,
                                    size: 18,
                                    color: (isCompleted || isCurrent) ? Colors.white : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (index < _trackingSteps.length - 1)
                                  Container(
                                    width: 2.5,
                                    height: 36,
                                    color: isCompleted ? Colors.green : colorScheme.outlineVariant,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step['title'] as String,
                                      style: TextStyle(
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 14,
                                        color: isPending
                                            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      step['desc'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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

                  const SizedBox(height: 20),

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

                  const SizedBox(height: 20),

                  // Order Cancellation Section (Configurable window enforcement)
                  if (canCancel)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cancellation Window Open: $remainingMinutes min remaining',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _showCancellationDialog(context, order),
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (windowExpired)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Order cancellation window ($cancellationWindowMinutes min) has expired. Meal is actively in prep.',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
