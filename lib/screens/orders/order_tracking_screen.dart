import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/review_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/status_badge.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../widgets/custom_button.dart';
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: cleanPhone));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phone number $cleanPhone copied to clipboard.'),
              backgroundColor: AppColors.brandMaroon,
            ),
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: cleanPhone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone $cleanPhone copied to clipboard.'),
            backgroundColor: AppColors.brandMaroon,
          ),
        );
      }
    }
  }

  static const List<Map<String, dynamic>> _coreTrackingSteps = [
    {
      'title': 'Order Placed',
      'desc': 'Order submitted to restaurant',
      'icon': Icons.receipt_long_rounded,
      'status': OrderStatus.pending,
    },
    {
      'title': 'Order Confirmed',
      'desc': 'Kitchen received and confirmed order',
      'icon': Icons.thumb_up_alt_rounded,
      'status': OrderStatus.accepted,
    },
    {
      'title': 'Preparing Food',
      'desc': 'Chefs are cooking fresh meal',
      'icon': Icons.soup_kitchen_rounded,
      'status': OrderStatus.preparing,
    },
    {
      'title': 'Order Ready',
      'desc': 'Meal packed and awaiting rider',
      'icon': Icons.inventory_2_rounded,
      'status': OrderStatus.ready,
    },
    {
      'title': 'Out for Delivery',
      'desc': 'Delivery champion is on the way',
      'icon': Icons.two_wheeler_rounded,
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
      } else if (args is String) {
        context.read<OrderProvider>().watchOrder(args);
      }
      _initialized = true;
    }
  }

  int _getTimelineStepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.accepted:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.ready:
        return 3;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  String _formatStepTime(DateTime baseTime, int stepIndex) {
    final stepTime = baseTime.add(Duration(minutes: stepIndex * 6));
    final hour = stepTime.hour % 12 == 0 ? 12 : stepTime.hour % 12;
    final minute = stepTime.minute.toString().padLeft(2, '0');
    final period = stepTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _statusHeadline(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.accepted:
        return 'Order Confirmed!';
      case OrderStatus.preparing:
        return 'Kitchen is Cooking!';
      case OrderStatus.ready:
        return 'Order is Ready!';
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return 'Your order is on the way!';
      case OrderStatus.delivered:
        return 'Order Delivered!';
      case OrderStatus.cancelled:
        return 'Order Cancelled';
    }
  }

  String _statusSubheadline(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Waiting for the restaurant to accept';
      case OrderStatus.accepted:
        return 'The chefs have confirmed your meal';
      case OrderStatus.preparing:
        return 'Fresh food is being prepared right now';
      case OrderStatus.ready:
        return 'Meal is packaged and awaiting pickup';
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return 'Our express rider is en route to you';
      case OrderStatus.delivered:
        return 'Thank you for choosing Food Fight!';
      case OrderStatus.cancelled:
        return 'This order has been cancelled';
    }
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkYellowSoft : AppColors.yellowSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.support_agent_rounded,
                      color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                      size: 24,
                    ),
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
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.success, size: 20),
                ),
                title: const Text('Call Restaurant Kitchen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('+92 300 1234567 • Fast response', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  _makePhoneCall('+923001234567');
                },
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkYellowSoft : AppColors.yellowSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                    size: 20,
                  ),
                ),
                title: const Text('Live Support Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Chat in real-time with Food Fight admin', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/chat', arguments: order.id);
                },
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

          return SafeArea(
            top: false,
            child: Container(
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
                  RadioGroup<String>(
                    groupValue: selectedReason,
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedReason = val);
                      }
                    },
                    child: Column(
                      children: reasons
                          .map((r) => RadioListTile<String>(
                                value: r,
                                title: Text(r, style: const TextStyle(fontSize: 13.5)),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: AppColors.error,
                              ))
                          .toList(),
                    ),
                  ),
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
                        child: CustomButton.destructive(
                          text: 'Confirm Cancel',
                          isLoading: _isCancelling,
                          onPressed: _isCancelling
                              ? null
                              : () async {
                                  final finalReason = selectedReason == 'Other reason'
                                      ? otherCtrl.text.trim()
                                      : selectedReason;

                                  final orderProv = context.read<OrderProvider>();
                                  final messenger = ScaffoldMessenger.of(context);
                                  setState(() => _isCancelling = true);
                                  Navigator.pop(ctx);

                                  final ok = await orderProv.updateOrderStatus(
                                        order.id,
                                        OrderStatus.cancelled,
                                        cancellationReason: finalReason,
                                      );

                                  if (mounted) {
                                    setState(() => _isCancelling = false);
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(ok
                                            ? 'Order cancelled successfully.'
                                            : 'Could not cancel order. Cancellation window may have expired.'),
                                        backgroundColor: ok ? AppColors.error : AppColors.warning,
                                      ),
                                    );
                                  }
                                },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = (orderProvider.currentOrder != null &&
            (_initialOrder == null || orderProvider.currentOrder!.id == _initialOrder?.id))
        ? orderProvider.currentOrder!
        : _initialOrder;

    if (order == null) {
      final theme = Theme.of(context);
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Order Live Tracking'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_rounded, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text('Order Not Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Unable to load live tracking information for this order.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandYellow, foregroundColor: AppColors.brandMaroon),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
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

    final hasRider = (order.riderId != null && order.riderId!.trim().isNotEmpty) ||
        (order.riderName != null && order.riderName!.trim().isNotEmpty);
    final riderDisplayName = (order.riderName != null && order.riderName!.trim().isNotEmpty)
        ? order.riderName!
        : 'Express Champion';
    final riderDisplayPhone = order.riderPhone ?? '';

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Hero Card (Reference G)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
                      ),
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
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkYellowSoft : AppColors.yellowSoft,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.brandYellow.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            isDelivered
                                ? Icons.check_circle_rounded
                                : (isCancelled ? Icons.cancel_rounded : Icons.two_wheeler_rounded),
                            color: isDelivered
                                ? AppColors.success
                                : (isCancelled
                                    ? AppColors.error
                                    : (isDark ? AppColors.brandYellow : AppColors.brandMaroon)),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statusHeadline(order.status),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _statusSubheadline(order.status),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Live Map Card (Only when rider is assigned)
                  if (!isCancelled) ...[
                    if (hasRider)
                      Stack(
                        children: [
                          LiveTrackingMapWidget(
                            orderId: order.id,
                            deliveryAddress: order.deliveryAddress,
                            isOutForDelivery: order.status == OrderStatus.outForDelivery,
                          ),
                          // ETA Badge Overlay (onYellow text on brandYellow fill)
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.brandYellow,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33FFD505),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_rounded, color: AppColors.onYellow, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    isDelivered ? 'Delivered' : 'ETA: 20–30 min',
                                    style: const TextStyle(
                                      color: AppColors.onYellow,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.brandYellow.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.two_wheeler_rounded, color: AppColors.brandMaroon, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rider Assignment in Progress',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Live GPS map will activate as soon as your rider picks up the order.',
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // 3. Rider Info Card
                  if (hasRider && !isCancelled) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
                        ),
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
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkYellowSoft : AppColors.yellowSoft,
                              border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.5)),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                size: 28,
                              ),
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
                                    Icon(
                                      Icons.two_wheeler_rounded,
                                      size: 13,
                                      color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                    ),
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
                          if (riderDisplayPhone.isNotEmpty)
                            InkWell(
                              onTap: () => _makePhoneCall(riderDisplayPhone),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: AppColors.successSoft,
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

                  // 4. Vertical Status Timeline (All 6 Stages, Reference G)
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
                        color: AppColors.errorSoft,
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
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
                        ),
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
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? AppColors.brandYellow
                                          : (isCurrent
                                              ? AppColors.brandYellow
                                              : colorScheme.surfaceContainerHighest),
                                      shape: BoxShape.circle,
                                      border: isCurrent
                                          ? Border.all(
                                              color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                              width: 2.5,
                                            )
                                          : null,
                                      boxShadow: isCurrent
                                          ? const [
                                              BoxShadow(
                                                color: Color(0x33FFD505),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      step['icon'] as IconData,
                                      size: 17,
                                      color: (isCompleted || isCurrent)
                                          ? AppColors.onYellow
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (index < _coreTrackingSteps.length - 1)
                                    Container(
                                      width: 2.5,
                                      height: 36,
                                      color: isCompleted
                                          ? AppColors.brandYellow
                                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2),
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
                                              fontSize: 14,
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
                                                color: isCurrent
                                                    ? (isDark ? AppColors.brandYellow : AppColors.amberDark)
                                                    : colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
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

                  // 5. Action Row: Primary Maroon Chat + Outlined Help + Outline-Error Cancel
                  if (canCancel)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CustomButton.darkCta(
                            text: 'Chat Support',
                            icon: Icons.chat_bubble_outline_rounded,
                            onPressed: () => Navigator.pushNamed(context, '/chat', arguments: order.id),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          style: IconButton.styleFrom(
                            foregroundColor: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                            side: BorderSide(
                              color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          tooltip: 'Help',
                          onPressed: () => _showGetHelpModal(context, order),
                          icon: const Icon(Icons.help_outline_rounded, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: CustomButton.destructive(
                            text: 'Cancel',
                            icon: Icons.close_rounded,
                            width: null,
                            onPressed: () => _showCancellationDialog(context, order),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton.darkCta(
                            text: 'Chat with Support',
                            icon: Icons.chat_bubble_outline_rounded,
                            onPressed: () => Navigator.pushNamed(context, '/chat', arguments: order.id),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                            side: BorderSide(
                              color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _showGetHelpModal(context, order),
                          child: const Icon(Icons.help_outline_rounded, size: 20),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // 6. Delivery Destination Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
                      ),
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
                            color: isDark ? AppColors.darkYellowSoft : AppColors.yellowSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_outlined,
                            color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                            size: 22,
                          ),
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

                  // 7. Sticky "Confirm Order Received" when delivered (Reference G)
                  if (isDelivered) ...[
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Order Received - Leave Review',
                      icon: Icons.rate_review_outlined,
                      onPressed: () => _showReviewOrderModal(context, order),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReviewOrderModal(BuildContext context, OrderModel order) {
    int selectedRating = 5;
    final commentCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (bottomSheetCtx, setModalState) {
          final theme = Theme.of(bottomSheetCtx);
          final colorScheme = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;

          return SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Icon(Icons.stars_rounded, color: AppColors.brandYellow, size: 44),
                    const SizedBox(height: 10),
                    Text(
                      'Rate Your Food Fight Experience',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Order #${order.orderNumber} • ${order.branchId}',
                      style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: List.generate(5, (idx) {
                        final star = idx + 1;
                        return InkWell(
                          onTap: () => setModalState(() => selectedRating = star),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Icon(
                              star <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: AppColors.mustard,
                              size: 38,
                            ),
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    maxLength: 250,
                    decoration: InputDecoration(
                      hintText: 'Tell us how the food tasted, delivery speed, packing...',
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandYellow,
                        foregroundColor: AppColors.brandMaroon,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              final auth = context.read<AuthProvider>();
                              final reviewProv = context.read<ReviewProvider>();
                              final user = auth.currentUser;

                              // Submit reviews for the first item in order
                              if (order.items.isNotEmpty && user != null) {
                                final firstItem = order.items.first;
                                await reviewProv.submitReview(
                                  ReviewModel(
                                    id: '',
                                    itemId: firstItem.food.id,
                                    branchId: order.branchId,
                                    userId: user.id,
                                    userName: user.name.isNotEmpty ? user.name : 'Foodie Champion',
                                    userAvatar: user.profileImage,
                                    rating: selectedRating.toDouble(),
                                    reviewText: commentCtrl.text.trim(),
                                    orderId: order.id,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  ),
                                );
                              }

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Thank you! Your verified review has been published.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandMaroon),
                            )
                          : const Text(
                              'Submit Review & Claim Tokens',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}
