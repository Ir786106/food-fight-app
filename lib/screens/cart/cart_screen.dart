import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/common/network_image_view.dart';
import '../../widgets/common/responsive_layout.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _useTokens = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final user = auth.currentUser;
        if (user != null) {
          Provider.of<LoyaltyProvider>(context, listen: false).watchAccount(user.id);
        }
      } catch (_) {}
    });
  }

  void _confirmClearCart(BuildContext context, CartProvider cart) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Clear Cart?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove all items from your cart?',
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('My Cart'),
            if (cart.items.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${cart.itemCount} items',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
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
              icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.error),
              label: const Text('Clear', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
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
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_bag_outlined, size: 72, color: AppColors.primary),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Your Food Fight Cart is Empty!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
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
                            text: 'Browse Menu',
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
              : CustomScrollView(
                  slivers: [
                    // Itemized Cart Items List
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = cart.items[index];
                            final hasVariant = item.selectedVariant != null ||
                                (item.selectedSize != null && item.selectedSize!.isNotEmpty);
                            final hasAddons = item.selectedAddons.isNotEmpty;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
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
                                          color: AppColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.food.category.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
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
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Main Item Row: Image, Name, and Quantities
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      NetworkImageView(
                                        imageUrl: item.food.imageUrl,
                                        width: 68,
                                        height: 68,
                                        borderRadius: 16,
                                        fallbackEmoji: item.food.imageEmoji,
                                      ),
                                      const SizedBox(width: 14),

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
                                                  color: item.quantity == 1 ? AppColors.error : AppColors.primary,
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
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(Icons.add, size: 15, color: AppColors.primary),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.tune_rounded, size: 12, color: AppColors.primary),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Size: ${item.selectedVariant?.label ?? item.selectedSize}',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
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
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.primary),
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

                                  const SizedBox(height: 10),
                                  Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                                  const SizedBox(height: 10),

                                  // Bottom Line: Line Total
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
                                          color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: cart.items.length,
                        ),
                      ),
                    ),

                    // Promo Code & Price Breakdown Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                        child: Container(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Loyalty Tokens Redemption Section
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.brandYellow.withValues(alpha: isDark ? 0.12 : 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.brandYellow.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.brandYellow.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Text('🎁', style: TextStyle(fontSize: 18)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Food Fight Loyalty Rewards',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                context.watch<LoyaltyProvider>().balance > 0
                                                    ? '${context.watch<LoyaltyProvider>().balance} tokens available (Rs. ${context.watch<LoyaltyProvider>().balance})'
                                                    : 'Earn 1 token for every Rs. 100 on delivered orders!',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (context.watch<LoyaltyProvider>().balance > 0)
                                          Switch(
                                            value: _useTokens,
                                            activeThumbColor: AppColors.brandYellow,
                                            onChanged: (val) {
                                              setState(() => _useTokens = val);
                                              if (val) {
                                                final bal = context.read<LoyaltyProvider>().balance;
                                                final maxRedeemable = bal.clamp(0, cart.subtotal.toInt());
                                                cart.applyTokens(maxRedeemable);
                                              } else {
                                                cart.clearTokens();
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                    if (_useTokens && context.watch<LoyaltyProvider>().balance > 0) ...[
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Redeem: ${cart.tokensToRedeem} Tokens',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            '- Rs. ${cart.loyaltyDiscount.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.success,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (context.watch<LoyaltyProvider>().balance > 1)
                                        Slider(
                                          value: cart.tokensToRedeem.toDouble().clamp(
                                                1.0,
                                                context
                                                    .watch<LoyaltyProvider>()
                                                    .balance
                                                    .clamp(1, cart.subtotal.toInt())
                                                    .toDouble(),
                                              ),
                                          min: 1.0,
                                          max: context
                                              .watch<LoyaltyProvider>()
                                              .balance
                                              .clamp(1, cart.subtotal.toInt())
                                              .toDouble(),
                                          divisions: context
                                                      .watch<LoyaltyProvider>()
                                                      .balance
                                                      .clamp(1, cart.subtotal.toInt()) >
                                                  1
                                              ? context
                                                  .watch<LoyaltyProvider>()
                                                  .balance
                                                  .clamp(1, cart.subtotal.toInt())
                                              : 1,
                                          activeColor: AppColors.brandYellow,
                                          onChanged: (val) {
                                            cart.applyTokens(val.toInt());
                                          },
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Separated Price Breakdown: Subtotal / Delivery Fee / Discount / Total
                              Text(
                                'Order Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _summaryRow(
                                context,
                                'Subtotal (${cart.itemCount} items)',
                                'Rs. ${cart.subtotal.toStringAsFixed(0)}',
                              ),
                              const SizedBox(height: 8),
                              _summaryRow(
                                context,
                                cart.selectedArea != null
                                    ? 'Delivery Fee (${cart.selectedArea!.name})'
                                    : 'Delivery Fee',
                                cart.isFreeDelivery ? 'FREE' : 'Rs. ${cart.deliveryFee.toStringAsFixed(0)}',
                                color: cart.isFreeDelivery ? AppColors.success : null,
                              ),
                              if (cart.loyaltyDiscount > 0) ...[
                                const SizedBox(height: 8),
                                _summaryRow(
                                  context,
                                  'Loyalty Tokens (${cart.tokensToRedeem} used)',
                                  '- Rs. ${cart.loyaltyDiscount.toStringAsFixed(0)}',
                                  color: AppColors.success,
                                ),
                              ],
                              const SizedBox(height: 12),
                              Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              _summaryRow(
                                context,
                                'Total',
                                'Rs. ${cart.total.toStringAsFixed(0)}',
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),

      // Sticky "Proceed to Checkout" Action Bar
      bottomNavigationBar: cart.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${cart.total.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: CustomButton(
                        text: 'Proceed to Checkout',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          final auth = context.read<AuthProvider>();
                          if (!auth.isLoggedIn) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please sign in to proceed to checkout'),
                                backgroundColor: AppColors.brandMaroon,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.of(context).pushNamed('/login');
                            return;
                          }
                          Navigator.of(context).pushNamed('/checkout');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
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
              color: color ??
                  (isBold
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.brandYellow
                          : AppColors.brandMaroon)
                      : colorScheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
