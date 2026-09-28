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
import '../../models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/branch_provider.dart';

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
        title: const Text('Checkout 🥊'),
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
                            child: const Row(
                              children: [
                                Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  'Add New',
                                  style: TextStyle(
                                    color: AppColors.primary,
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
                                    color: isSelected ? AppColors.primary : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? AppColors.primary.withValues(alpha: 0.35)
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
                                        color: isSelected ? Colors.white : AppColors.primary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        addr.label,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : colorScheme.onSurface,
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
                          prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
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
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
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
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Standard Express Delivery: Rs. 150 (Citywide)',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
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
                                    ? AppColors.primary
                                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                                width: isSelected ? 1.8 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.15)
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
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    opt['icon'] as IconData,
                                    color: isSelected ? AppColors.primary : colorScheme.onSurfaceVariant,
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
                                  color: isSelected ? AppColors.primary : colorScheme.onSurfaceVariant,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),

                      // 4. Order Summary Breakdown (Identical in style to Cart's)
                      Text(
                        'Order Summary',
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
                            if (cart.couponDiscount > 0) ...[
                              const SizedBox(height: 8),
                              _summaryRow(
                                context,
                                'Coupon Discount (${cart.appliedCoupon?.code})',
                                '- Rs. ${cart.couponDiscount.toStringAsFixed(0)}',
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

      // Sticky "Place Order" / "Confirmation" Button
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isPlacingOrder ? null : () => _submitOrder(cart, auth),
                  icon: _isPlacingOrder
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                  label: Text(
                    _isPlacingOrder ? 'Placing Order...' : 'Place Order',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
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
              color: color ?? (isBold ? AppColors.primary : colorScheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
