import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/common/network_image_view.dart';
import '../../widgets/common/responsive_layout.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponCtrl = TextEditingController();
  bool _isApplyingCoupon = false;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(CartProvider cart) async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() => _isApplyingCoupon = true);
    final success = await cart.applyCoupon(code);
    if (!mounted) return;
    setState(() => _isApplyingCoupon = false);

    if (success) {
      _couponCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coupon applied successfully! 🎉'), backgroundColor: Colors.green),
      );
    } else {
      final err = cart.couponError ?? 'Invalid coupon code';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmClearCart(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              cart.clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('My Cart 🥊'),
            if (cart.items.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${cart.itemCount} items',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClearCart(context, cart),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
              label: const Text('Clear', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer.content(
          maxWidth: 860,
          child: cart.items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.shopping_bag_outlined, size: 72, color: colorScheme.primary),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Your Food Fight Cart is Empty!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You haven\'t added any delicious food yet.\nExplore our signature pizzas, burgers, and platters!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: 220,
                          child: CustomButton(
                            text: 'Browse Menu 🍔',
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Itemized Cart Items List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          final hasVariant = item.selectedVariant != null || (item.selectedSize != null && item.selectedSize!.isNotEmpty);
                          final hasAddons = item.selectedAddons.isNotEmpty;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: colorScheme.outlineVariant),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Category tag & delete button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.food.category.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme.primary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        cart.removeFromCart(item.food.id, lineKey: item.lineKey);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Removed ${item.displayName} from cart'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Colors.red.shade400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Main Item Row: Image, Name, and Quantities
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    NetworkImageView(
                                      imageUrl: item.food.imageUrl,
                                      width: 64,
                                      height: 64,
                                      borderRadius: 14,
                                      fallbackEmoji: item.food.imageEmoji,
                                    ),
                                    const SizedBox(width: 12),

                                    // Title & Unit Pricing
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.food.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Unit: Rs. ${item.singleUnitPrice.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Stepper
                                    Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: colorScheme.outlineVariant),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => cart.decrementQuantity(item.food.id, lineKey: item.lineKey),
                                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              child: Icon(
                                                item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove,
                                                size: 15,
                                                color: item.quantity == 1 ? Colors.red : colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6),
                                            child: Text(
                                              '${item.quantity}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 13,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => cart.incrementQuantity(item.food.id, lineKey: item.lineKey),
                                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              child: Icon(Icons.add, size: 15, color: colorScheme.primary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Highlight Selected Variant/Size
                                if (hasVariant) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.tune_rounded, size: 13, color: colorScheme.primary),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Size: ${item.selectedVariant?.label ?? item.selectedSize}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Highlight Itemized Extras & Addons
                                if (hasAddons) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: item.selectedAddons.map((addon) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle_rounded, size: 12, color: colorScheme.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${addon.name} (+Rs. ${addon.price.toStringAsFixed(0)})',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],

                                const Divider(height: 18),

                                // Bottom Line: Total for this item
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${item.quantity} × Rs. ${item.singleUnitPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom Summary & Checkout Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Promo Code Section
                            if (cart.appliedCoupon == null) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _couponCtrl,
                                      textCapitalization: TextCapitalization.characters,
                                      style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: 'Enter Coupon (e.g. FIGHTBOGO)',
                                        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12.5),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _isApplyingCoupon ? null : () => _applyCoupon(cart),
                                    child: _isApplyingCoupon
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_offer, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Coupon "${cart.appliedCoupon!.code}" applied!',
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                      onPressed: () => cart.removeCoupon(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Detailed Bill Breakdown
                            _summaryRow(context, 'Subtotal (${cart.itemCount} items)', 'Rs. ${cart.subtotal.toStringAsFixed(0)}'),
                            const SizedBox(height: 5),
                            if (cart.couponDiscount > 0) ...[
                              _summaryRow(
                                context,
                                'Coupon Discount',
                                '- Rs. ${cart.couponDiscount.toStringAsFixed(0)}',
                                color: Colors.green,
                              ),
                              const SizedBox(height: 5),
                            ],
                            _summaryRow(
                              context,
                              cart.selectedArea != null
                                  ? 'Delivery Fee (${cart.selectedArea!.name})'
                                  : 'Delivery Fee',
                              cart.isFreeDelivery ? 'FREE' : 'Rs. ${cart.deliveryFee.toStringAsFixed(0)}',
                              color: cart.isFreeDelivery ? Colors.green : null,
                            ),
                            Divider(height: 18, color: colorScheme.outlineVariant),
                            _summaryRow(
                              context,
                              'Grand Total',
                              'Rs. ${cart.total.toStringAsFixed(0)}',
                              isBold: true,
                            ),
                            const SizedBox(height: 16),

                            // Proceed to Checkout CTA
                            CustomButton(
                              text: 'Proceed to Checkout • Rs. ${cart.total.toStringAsFixed(0)}',
                              onPressed: () => Navigator.of(context).pushNamed('/checkout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value, {bool isBold = false, Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 13.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
              color: isBold ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 13.5,
              fontWeight: FontWeight.w900,
              color: color ?? (isBold ? colorScheme.primary : colorScheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
