import 'package:flutter/material.dart';

import '../../core/localization/app_language.dart';

class CheckoutPaymentSection extends StatelessWidget {
  const CheckoutPaymentSection({super.key});

  static const cashOnDelivery = 'Cash on Delivery';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('Payment Method'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Card.outlined(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: Text(context.tr(cashOnDelivery)),
            subtitle: Text(context.tr('Pay in cash when your order arrives')),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('Online payment is currently unavailable.'),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
