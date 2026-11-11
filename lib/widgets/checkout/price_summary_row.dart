import 'package:flutter/material.dart';

import '../../core/theme/design_system.dart';

/// Shared money breakdown row for cart and checkout.
class PriceSummaryRow extends StatelessWidget {
  const PriceSummaryRow({
    super.key,
    required this.label,
    required this.amount,
    this.emphasized = false,
    this.amountColor,
  });

  final String label;
  final String amount;
  final bool emphasized;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style =
        emphasized ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label,
              style: style?.copyWith(
                color: emphasized ? colors.onSurface : colors.onSurfaceVariant,
              )),
        ),
        const SizedBox(width: DesignSystem.space12),
        Flexible(
          child: Text(
            amount,
            textAlign: TextAlign.end,
            style: style?.copyWith(
              color: amountColor ??
                  (emphasized ? colors.primary : colors.onSurface),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
