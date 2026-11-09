import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_language.dart';
import '../../providers/cart_provider.dart';
import '../common/network_image_view.dart';

class DesktopCartPanel extends StatelessWidget {
  const DesktopCartPanel({super.key, required this.onOpenCart});

  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider?>();
    final items = cart?.items ?? [];
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: colors.surface,
        border: BorderDirectional(start: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(context.tr('Your bag'), style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          context.tr('Your bag is empty'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: SizedBox.square(
                              dimension: 42,
                              child: NetworkImageView(imageUrl: item.food.imageUrl),
                            ),
                            title: Text(item.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${item.quantity} × Rs. ${item.singleUnitPrice.toStringAsFixed(0)}'),
                          );
                        },
                      ),
              ),
              if (items.isNotEmpty) ...[
                const Divider(),
                Row(
                  children: [
                    Expanded(child: Text(context.tr('Subtotal'))),
                    Text('Rs. ${cart!.subtotal.toStringAsFixed(0)}', style: theme.textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(onPressed: onOpenCart, child: Text(context.tr('View cart'))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
