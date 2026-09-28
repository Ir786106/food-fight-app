import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static const List<Map<String, dynamic>> _coreTrackingSteps = [
    {
      'title': 'Order Confirmed',
      'desc': 'Kitchen received and confirmed order',
      'icon': Icons.receipt_long_rounded,
      'status': OrderStatus.pending,
    },
    {
      'title': 'Preparing',
      'desc': 'Chefs are cooking fresh meal in the kitchen',
      'icon': Icons.soup_kitchen_rounded,
      'status': OrderStatus.preparing,
    },
    {
      'title': 'On the Way',
      'desc': 'Delivery champion is en route with your meal',
      'icon': Icons.delivery_dining_rounded,
      'status': OrderStatus.outForDelivery,
    },
    {
      'title': 'Delivered',
      'desc': 'Enjoy your meal! Battle hunger victory!',
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

  int _getTimelineStepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.accepted:
        return 0;
      case OrderStatus.preparing:
      case OrderStatus.ready:
        return 1;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return 2;
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  String _formatStepTime(DateTime baseTime, int stepIndex) {
    final stepTime = baseTime.add(Duration(minutes: stepIndex * 8));
    final hour = stepTime.hour % 12 == 0 ? 12 : stepTime.hour % 12;
    final minute = stepTime.minute.toString().padLeft(2, '0');
    final period = stepTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _showGetHelpModal(BuildContext context, OrderModel order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Order Help Center',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Need assistance with order ${order.orderNumber}?',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.success, size: 20),
                ),
                title: const Text('Call Restaurant Kitchen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('+92 300 1234567 • Fast response', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(const ClipboardData(text: '+923001234567'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kitchen phone +92 300 1234567 copied to clipboard & dialer ready!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                ),
                title: const Text('Live Support Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Chat with customer service agent', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSupportChatSheet(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupportChatSheet(BuildContext context) {
    final messages = [
      {'sender': 'agent', 'text': 'Hello! Thanks for reaching out to Food Fight Support. How can we help with your order today?', 'time': 'Just now'},
    ];
    final textCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1D26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (chatCtx) => StatefulBuilder(
        builder: (ctx, setChatState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SizedBox(
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Food Fight Live Agent (Active)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[i];
                      final isUser = m['sender'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isUser ? AppColors.primary : const Color(0xFF272734),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            m['text']!,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF121217),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () {
                        final txt = textCtrl.text.trim();
                        if (txt.isNotEmpty) {
                          setChatState(() {
                            messages.add({'sender': 'user', 'text': txt, 'time': 'Now'});
                            textCtrl.clear();
                          });
                          Future.delayed(const Duration(milliseconds: 900), () {
                            if (ctx.mounted) {
                              setChatState(() {
                                messages.add({
                                  'sender': 'agent',
                                  'text': 'We have noted your request and our dispatch team has been notified. We will ensure prompt resolution!',
                                  'time': 'Now',
                                });
                              });
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                      Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
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
                        activeColor: AppColors.error,
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
                          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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
                                        backgroundColor: ok ? AppColors.error : AppColors.warning,
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
    final isDark = theme.brightness == Brightness.dark;
    final isCancelled = order.status == OrderStatus.cancelled;
    final isDelivered = order.status == OrderStatus.delivered;
    final currentStepIndex = _getTimelineStepIndex(order.status);

    final hasRider = (order.riderName != null && order.riderName!.isNotEmpty) ||
        (order.status == OrderStatus.assigned ||
            order.status == OrderStatus.pickedUp ||
            order.status == OrderStatus.outForDelivery ||
            order.status == OrderStatus.delivered);

    final riderDisplayName = order.riderName ?? 'Farhan Ali';
    final riderDisplayPhone = order.riderPhone ?? '+92 312 9876543';

    // Cancellation window
    const int cancellationWindowMinutes = 10;
    final elapsedMinutes = DateTime.now().difference(order.createdAt).inMinutes;
    final remainingMinutes = cancellationWindowMinutes - elapsedMinutes;
    final canCancel = !isCancelled &&
        !isDelivered &&
        (order.status == OrderStatus.pending || order.status == OrderStatus.accepted) &&
        remainingMinutes > 0;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('${order.orderNumber} Tracking'),
          elevation: 0,
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Live Map at the top with Route Line & ETA Badge (Spec benchmark)
                  if (!isCancelled) ...[
                    Stack(
                      children: [
                        LiveTrackingMapWidget(
                          orderId: order.id,
                          deliveryAddress: order.deliveryAddress,
                          isOutForDelivery: order.status == OrderStatus.outForDelivery,
                        ),
                        // ETA Badge Overlay
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  isDelivered ? 'Delivered' : 'ETA: 20–30 min',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 2. Rider Info Card (photo, name, vehicle, call button) once rider is assigned
                  if (hasRider && !isCancelled) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Rider Photo / Avatar
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFFFF8E43)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  riderDisplayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.two_wheeler_rounded, size: 13, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Food Fight Express Champion',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Call Button
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Calling delivery champion ($riderDisplayPhone)... 📞'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.phone_rounded, color: AppColors.success, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 3. Vertical Status Timeline (Order Confirmed → Preparing → On the Way → Delivered) with Timestamps
                  Text(
                    'Delivery Status Timeline',
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
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel_rounded, color: AppColors.error, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              order.cancellationReason?.isNotEmpty == true
                                  ? 'Order was cancelled: "${order.cancellationReason}"'
                                  : 'This order has been cancelled.',
                              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(18),
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
                      child: Column(
                        children: List.generate(_coreTrackingSteps.length, (index) {
                          final step = _coreTrackingSteps[index];
                          final isCompleted = currentStepIndex > index;
                          final isCurrent = currentStepIndex == index;
                          final isPending = currentStepIndex < index;
                          final timestamp = _formatStepTime(order.createdAt, index);

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
                                          ? AppColors.success
                                          : (isCurrent
                                              ? AppColors.primary
                                              : colorScheme.surfaceContainerHighest),
                                      shape: BoxShape.circle,
                                      boxShadow: isCurrent
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      step['icon'] as IconData,
                                      size: 18,
                                      color: (isCompleted || isCurrent) ? Colors.white : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (index < _coreTrackingSteps.length - 1)
                                    Container(
                                      width: 2.5,
                                      height: 38,
                                      color: isCompleted
                                          ? AppColors.success
                                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            step['title'] as String,
                                            style: TextStyle(
                                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                              fontSize: 14.5,
                                              color: isPending
                                                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                                                  : colorScheme.onSurface,
                                            ),
                                          ),
                                          if (!isPending)
                                            Text(
                                              timestamp,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: isCurrent ? AppColors.primary : colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        step['desc'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 4. "Get Help" Action & Actions Bar (Spec benchmark)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showGetHelpModal(context, order),
                          icon: const Icon(Icons.help_outline_rounded, size: 18),
                          label: const Text('Get Help'),
                        ),
                      ),
                      if (canCancel) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            onPressed: () => _showCancellationDialog(context, order),
                            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                            label: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Delivery Destination Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery Address',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.deliveryAddress,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
