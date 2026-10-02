import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_area_provider.dart';
import '../../providers/payment_method_provider.dart';
import '../../models/delivery_area_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/network_image_view.dart';
import '../../widgets/custom_button.dart';
import '../../models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/loyalty_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  String _selectedAddressLabel = 'Home';
  String _selectedPayment = 'Cash on Delivery';
  bool _isPlacingOrder = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<PaymentMethodProvider>().watchMethods(user.id);
        context.read<AddressProvider>().watchAddresses(user.id);
      }
      _initialized = true;
    }

    // Pre-fill address from saved addresses (only if not yet set by user)
    if (_addressCtrl.text.isEmpty) {
      final addressProvider = context.read<AddressProvider>();
      final addresses = addressProvider.addresses;
      if (addresses.isNotEmpty) {
        final defaultOrFirst = addressProvider.defaultAddress ?? addresses.first;
        _selectedAddressLabel = defaultOrFirst.label;
        _addressCtrl.text = defaultOrFirst.details;
      }
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(CartProvider cart, AuthProvider auth) async {
    final addressText = _addressCtrl.text.trim();
    if (addressText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full delivery address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!auth.isLoggedIn || auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to place your order'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.of(context).pushNamed('/login');
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final customerId = auth.currentUser!.id;
      final customerName = auth.currentUser!.name.isNotEmpty ? auth.currentUser!.name : 'Customer';
      final customerPhone = auth.currentUser!.phone;
      final paymentStatus = _selectedPayment == 'Cash on Delivery' ? 'pending' : 'paid';
      final zoneName = cart.selectedArea != null ? '${cart.selectedArea!.name} - ' : '';
      final fullAddress = '$zoneName$addressText';

      final branchProv = context.read<BranchProvider>();
      final selectedBranch = branchProv.selectedBranch;
      final branchId = cart.branchId ?? selectedBranch?.id;
      final restaurantName = selectedBranch?.name ?? 'Food Fight Restaurant';

      final placedOrder = await cart.placeOrder(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        deliveryAddress: fullAddress,
        paymentMethod: _selectedPayment,
        paymentStatus: paymentStatus,
        restaurantName: restaurantName,
        branchId: branchId,
      );

      // Redeem loyalty tokens atomically if used
      if (cart.tokensToRedeem > 0 && mounted) {
        await context.read<LoyaltyProvider>().redeemTokens(
              userId: customerId,
              tokensToRedeem: cart.tokensToRedeem,
              orderId: placedOrder.id,
            );
      }

      if (!mounted) return;
      setState(() => _isPlacingOrder = false);

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/order-success',
        (r) => r.settings.name == '/home',
        arguments: placedOrder,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final areaProvider = context.watch<DeliveryAreaProvider>();
    final payProvider = context.watch<PaymentMethodProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final deliveryAreas = areaProvider.activeAreas;
    final addresses = addressProvider.addresses;


    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Automatically set default area if not yet selected
    if (deliveryAreas.isNotEmpty && cart.selectedArea == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cart.setDeliveryArea(deliveryAreas.first);
      });
    }

    // Payment options list: default COD + saved cards/wallets + fallbacks
    final List<Map<String, dynamic>> paymentOptions = [
      {
        'id': 'Cash on Delivery',
        'title': 'Cash on Delivery',
        'subtitle': 'Pay in cash when rider arrives at your doorstep',
        'icon': Icons.payments_outlined,
      },
    ];

    if (payProvider.methods.isNotEmpty) {
      for (var m in payProvider.methods) {
        final brandName = (m.cardBrand ?? m.gateway).toUpperCase();
        paymentOptions.add({
          'id': '$brandName ${m.maskedNumber}',
          'title': '$brandName Card',
          'subtitle': '${m.maskedNumber} (Saved)',
          'icon': Icons.credit_card_rounded,
        });
      }
    } else {
      paymentOptions.add({
        'id': 'Credit / Debit Card (Online)',
        'title': 'Credit / Debit Card',
        'subtitle': 'Visa, Mastercard with 256-bit encryption',
        'icon': Icons.credit_card_outlined,
      });
      paymentOptions.add({
        'id': 'Easypaisa / JazzCash',
        'title': 'E-Wallets',
        'subtitle': 'JazzCash, Easypaisa instant mobile transfer',
        'icon': Icons.account_balance_wallet_outlined,
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveContainer.content(
          maxWidth: 860,
          child: areaProvider.isLoading && deliveryAreas.isEmpty
              ? const LoadingIndicator(message: 'Loading delivery coverage...')
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Saved Address Selector as Chips/Cards (Home, Work, +Add new)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery Address',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final res = await Navigator.of(context).pushNamed('/add-address');
                              if (res is AddressModel) {
                                setState(() {
                                  _selectedAddressLabel = res.label;
                                  _addressCtrl.text = res.details;
                                });
                              }
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: isDark ? AppColors.brandYellow : AppColors.amberDark,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Add New',
                                  style: TextStyle(
                                    color: isDark ? AppColors.brandYellow : AppColors.amberDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Address Chips Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...addresses.map((addr) {
                              final isSelected = _selectedAddressLabel == addr.label;
                              IconData icon = Icons.home_outlined;
                              final type = addr.iconType.toLowerCase();
                              if (type == 'work' || type == 'office') {
                                icon = Icons.work_outline_rounded;
                              } else if (type == 'other' || type == 'place') {
                                icon = Icons.place_outlined;
                              }
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedAddressLabel = addr.label;
                                    _addressCtrl.text = addr.details;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.brandYellow : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.yellowPressed
                                          : colorScheme.outlineVariant.withValues(alpha: 0.6),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? AppColors.brandYellow.withValues(alpha: 0.35)
                                            : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        color: isSelected
                                            ? AppColors.onYellow
                                            : (isDark ? AppColors.brandYellow : AppColors.brandMaroon),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        addr.label,
                                        style: TextStyle(
                                          color: isSelected ? AppColors.onYellow : colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            GestureDetector(
                              onTap: () async {
                                final res = await Navigator.of(context).pushNamed('/add-address');
                                if (res is AddressModel) {
                                  setState(() {
                                    _selectedAddressLabel = res.label;
                                    _addressCtrl.text = res.details;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, color: colorScheme.onSurfaceVariant, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Add Address',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Detailed address input
                      TextField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'House / Apartment #, Street, Block, Nearby Landmark...',
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Delivery Zone Selection
                      Text(
                        'Delivery Area & Coverage',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (deliveryAreas.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<DeliveryAreaModel>(
                              isExpanded: true,
                              dropdownColor: colorScheme.surface,
                              value: (cart.selectedArea != null && deliveryAreas.contains(cart.selectedArea))
                                  ? cart.selectedArea
                                  : (deliveryAreas.isNotEmpty ? deliveryAreas.first : null),
                              items: deliveryAreas.map((area) {
                                return DropdownMenuItem(
                                  value: area,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          area.name,
                                          style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Rs. ${area.deliveryCharge.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) cart.setDeliveryArea(val);
                              },
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkYellowSoft : AppColors.yellowSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.brandYellow.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Standard Express Delivery: Rs. 150 (Citywide)',
                            style: TextStyle(
                              color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // 3. Payment Method Selector as Radio List
                      Text(
                        'Payment Method',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...paymentOptions.map((opt) {
                        final isSelected = _selectedPayment == opt['id'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedPayment = opt['id'] as String),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.brandYellow
                                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                                width: isSelected ? 1.8 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.brandYellow.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.brandYellow.withValues(alpha: 0.18)
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    opt['icon'] as IconData,
                                    color: isSelected
                                        ? (isDark ? AppColors.brandYellow : AppColors.brandMaroon)
                                        : colorScheme.onSurfaceVariant,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        opt['title'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        opt['subtitle'] as String,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                  color: isSelected
                                      ? (isDark ? AppColors.brandYellow : AppColors.brandMaroon)
                                      : colorScheme.onSurfaceVariant,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),

                      // 4. Items in Order Breakdown (Reference F)
                      Text(
                        'Items in Order (${cart.itemCount})',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
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
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cart.items.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 16,
                            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                          itemBuilder: (context, idx) {
                            final item = cart.items[idx];
                            final hasVariant = item.selectedVariant != null ||
                                (item.selectedSize != null && item.selectedSize!.isNotEmpty);
                            return Row(
                              children: [
                                NetworkImageView(
                                  imageUrl: item.food.imageUrl,
                                  width: 48,
                                  height: 48,
                                  borderRadius: 12,
                                  fallbackEmoji: item.food.imageEmoji,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.food.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      if (hasVariant)
                                        Text(
                                          'Size: ${item.selectedVariant?.label ?? item.selectedSize}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      Text(
                                        'Qty: ${item.quantity}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5. Order Summary Breakdown
                      Text(
                        'Fee Breakdown',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
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
                          children: [
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
                                'Loyalty Tokens (${cart.tokensToRedeem} redeemed)',
                                '- Rs. ${cart.loyaltyDiscount.toStringAsFixed(0)}',
                                color: AppColors.success,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            _summaryRow(
                              context,
                              'Total Amount',
                              'Rs. ${cart.total.toStringAsFixed(0)}',
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),

      // Sticky "Place Order" Action Bar
      bottomNavigationBar: Container(
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
                    'Grand Total',
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
                  text: _isPlacingOrder ? 'Placing Order...' : 'Place Order',
                  isLoading: _isPlacingOrder,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: _isPlacingOrder ? null : () => _submitOrder(cart, auth),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              color: color ?? (isBold ? (isDark ? AppColors.brandYellow : AppColors.brandMaroon) : colorScheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
