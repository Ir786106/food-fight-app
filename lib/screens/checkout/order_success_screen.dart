import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/responsive_layout.dart';

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
                  // Celebratory Checkmark Icon with Glow
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Celebratory Title
                  Text(
                    'Your order has been placed successfully! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Order ID badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_rounded, size: 15, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Order ID: ${order.orderNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Estimated Delivery Time Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.timer_rounded, color: AppColors.primary, size: 24),
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
                            color: AppColors.success.withValues(alpha: 0.15),
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

                  // Order Summary breakdown card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _row(context, 'Total Amount', 'Rs. ${order.total.toStringAsFixed(0)}', isBold: true),
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

                  // Notifications note
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

                  // Action Buttons: "View Order Status" & "Continue Shopping"
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed('/order-tracking', arguments: order),
                      icon: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 22),
                      label: const Text(
                        'View Order Status',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil('/home', (r) => false),
                      child: const Text(
                        'Continue Shopping',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
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

  Widget _row(BuildContext context, String label, String value, {bool isMultiline = false, bool isBold = false}) {
    final colorScheme = Theme.of(context).colorScheme;

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
              fontSize: isBold ? 15 : 13,
              fontWeight: FontWeight.w700,
              color: isBold ? AppColors.primary : colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
