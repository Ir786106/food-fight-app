import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as OrderModel;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('🏆', style: TextStyle(fontSize: 60)),
              ),
              const SizedBox(height: 28),
              const Text(
                'Order Placed!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your Food Fight order ${order.orderNumber} has been sent to our kitchen. Sit tight, the battle is on!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _row('Order Number', order.orderNumber),
                    const SizedBox(height: 10),
                    _row('Total Amount', 'Rs. ${order.total.toStringAsFixed(0)}'),
                    const SizedBox(height: 10),
                    _row('Payment Method', order.paymentMethod.toUpperCase()),
                    const SizedBox(height: 10),
                    _row('Delivery Address', order.deliveryAddress, isMultiline: true),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              CustomButton(
                text: 'Track Order Live 🛵',
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed('/order-tracking', arguments: order),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Back to Home',
                isOutlined: true,
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (r) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isMultiline = false}) {
    return Row(
      crossAxisAlignment:
          isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
