import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';

/// Clean Vertical Delivery Status Timeline Card for OrderTrackingScreen
class TrackingTimelineCard extends StatelessWidget {
  final OrderModel order;
  final int currentStepIndex;

  const TrackingTimelineCard({
    super.key,
    required this.order,
    required this.currentStepIndex,
  });

  static const List<Map<String, dynamic>> _coreTrackingSteps = [
    {
      'title': 'Order Placed',
      'subtitle': 'Sent to kitchen for acceptance',
      'icon': Icons.receipt_long_rounded,
    },
    {
      'title': 'Order Confirmed',
      'subtitle': 'Kitchen accepted and queued order',
      'icon': Icons.check_circle_outline_rounded,
    },
    {
      'title': 'Preparing in Kitchen',
      'subtitle': 'Chefs are grilling and cooking fresh',
      'icon': Icons.outdoor_grill_rounded,
    },
    {
      'title': 'Ready for Pickup',
      'subtitle': 'Packed and waiting at the counter',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'title': 'Out for Delivery',
      'subtitle': 'Rider is on the way to your door',
      'icon': Icons.delivery_dining_rounded,
    },
    {
      'title': 'Delivered',
      'subtitle': 'Enjoy your Food Fight meal!',
      'icon': Icons.task_alt_rounded,
    },
  ];

  String _formatStepTime(DateTime baseTime, int stepIndex) {
    final stepTime = baseTime.add(Duration(minutes: stepIndex * 6));
    final hour = stepTime.hour % 12 == 0 ? 12 : stepTime.hour % 12;
    final minute = stepTime.minute.toString().padLeft(2, '0');
    final period = stepTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isCancelled = order.status == OrderStatus.cancelled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                                    fontSize: 14.5,
                                    color: isPending
                                        ? colorScheme.onSurfaceVariant
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  timestamp,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isCurrent
                                        ? (isDark ? AppColors.brandYellow : AppColors.brandMaroon)
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              step['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (index < _coreTrackingSteps.length - 1)
                              const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }
}
