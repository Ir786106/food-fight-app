import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../core/constants/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../widgets/common/network_image_view.dart';
import '../../widgets/custom_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rawOrder = ModalRoute.of(context)?.settings.arguments;
    final order = rawOrder is OrderModel
        ? rawOrder
        : OrderModel(
            id: '',
            orderNumber: 'FF-LIVE',
            items: const [],
            subtotal: 0,
            total: 0,
            paymentMethod: 'Cash on Delivery',
            deliveryAddress: 'Your specified address',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            customerId: '',
            restaurantName: 'Food Fight HQ',
          );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ResponsiveContainer.content(
          maxWidth: 600,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Concentric Yellow Rings with Checkmark (Reference F)
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: AppColors.brandYellow.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.brandYellow.withValues(alpha: 0.28),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.brandYellow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33FFD505),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 34,
                          color: AppColors.onYellow,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Celebratory Title (no raw emoji, Audit 16)
                  Text(
                    'Order Placed Successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Order ID Pill (maroon text on yellowSoft, Audit 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkYellowSoft : AppColors.yellowSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.brandYellow.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_rounded,
                          size: 15,
                          color: isDark ? AppColors.brandYellow : AppColors.onYellow,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Order ID: ${order.orderNumber}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.brandYellow : AppColors.onYellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Estimated Delivery Time Card
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
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkYellowSoft : AppColors.yellowSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.timer_rounded,
                            color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated Delivery Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '25 – 35 minutes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'On Schedule',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Items Ordered Card (Reference F)
                  if (order.items.isNotEmpty) ...[
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
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Items Ordered',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...order.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  NetworkImageView(
                                    imageUrl: item.food.imageUrl,
                                    width: 38,
                                    height: 38,
                                    borderRadius: 10,
                                    fallbackEmoji: item.food.imageEmoji,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          'Qty: ${item.quantity}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 4. Receipt & Fee Breakdown Card (Reference F)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _row(
                          context,
                          'Total Amount',
                          'Rs. ${order.total.toStringAsFixed(0)}',
                          isBold: true,
                          highlightValue: true,
                        ),
                        const SizedBox(height: 10),
                        _row(context, 'Payment Method', order.paymentMethod.toUpperCase()),
                        const SizedBox(height: 10),
                        _row(context, 'Kitchen', order.restaurantName),
                        const SizedBox(height: 10),
                        _row(context, 'Delivery Address', order.deliveryAddress, isMultiline: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notifications Note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_active_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Live updates will be sent via push notification, email, and SMS.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 5. Action Buttons (Track Order + Continue Shopping)
                  CustomButton(
                    text: 'Track Order',
                    icon: Icons.delivery_dining_rounded,
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed('/order-tracking', arguments: order),
                  ),
                  const SizedBox(height: 12),
                  CustomButton.outlined(
                    text: 'Continue Shopping',
                    icon: Icons.storefront_rounded,
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil('/home', (r) => false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool isMultiline = false,
    bool isBold = false,
    bool highlightValue = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isBold ? 16 : 13,
              fontWeight: FontWeight.w700,
              color: highlightValue
                  ? (isDark ? AppColors.brandYellow : AppColors.brandMaroon)
                  : colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
