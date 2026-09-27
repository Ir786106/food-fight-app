import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_area_provider.dart';
import '../../models/delivery_area_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../widgets/common/loading_indicator.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  String _selectedPayment = 'Cash on Delivery';
  bool _isPlacingOrder = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Cash on Delivery', 'icon': Icons.money},
    {'name': 'Credit / Debit Card (Online)', 'icon': Icons.credit_card},
    {'name': 'Easypaisa / JazzCash', 'icon': Icons.phone_android},
  ];

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(CartProvider cart, AuthProvider auth) async {
    final addressText = _addressCtrl.text.trim();
    if (addressText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full delivery address'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final customerId = auth.currentUser?.id ?? 'guest_user';
      final customerName = auth.currentUser?.name ?? 'Guest Customer';
      final customerPhone = auth.currentUser?.phone ?? '';
      final paymentStatus = _selectedPayment == 'Cash on Delivery' ? 'pending' : 'paid';
      final zoneName = cart.selectedArea != null ? '${cart.selectedArea!.name} - ' : '';
      final fullAddress = '$zoneName$addressText';

      final placedOrder = await cart.placeOrder(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        deliveryAddress: fullAddress,
        paymentMethod: _selectedPayment,
        paymentStatus: paymentStatus,
        restaurantName: 'Food Fight Restaurant',
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
        SnackBar(content: Text('Error placing order: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final areaProvider = context.watch<DeliveryAreaProvider>();
    final deliveryAreas = areaProvider.activeAreas;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Automatically set default area if not yet selected
    if (deliveryAreas.isNotEmpty && cart.selectedArea == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cart.setDeliveryArea(deliveryAreas.first);
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Checkout 🥊')),
      body: SafeArea(
        child: ResponsiveContainer.content(
          maxWidth: 860,
          child: areaProvider.isLoading && deliveryAreas.isEmpty
              ? const LoadingIndicator(message: 'Loading delivery coverage...')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Delivery Zone Selection
                      Text(
                        'Delivery Area & Coverage',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),

                      if (deliveryAreas.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colorScheme.outlineVariant),
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
                                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'Standard Delivery: Rs. 150 (Citywide)',
                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Delivery Address Input
                      Text(
                        'Detailed Delivery Address',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'House / Apartment #, Street, Block, Nearby Landmark...',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Payment Method Selector
                      Text(
                        'Payment Method',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 12),
                      ..._paymentMethods.map((method) {
                        final isSelected = _selectedPayment == method['name'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedPayment = method['name']),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.08)
                                  : colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  method['icon'] as IconData,
                                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    method['name'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? colorScheme.primary : Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 24),

                      // Order Summary Card
                      Text(
                        'Order Summary',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow('Items Subtotal', 'Rs. ${cart.subtotal.toStringAsFixed(0)}', colorScheme),
                            const SizedBox(height: 8),
                            _buildSummaryRow(
                              'Delivery Fee',
                              cart.isFreeDelivery ? 'FREE' : 'Rs. ${cart.deliveryFee.toStringAsFixed(0)}',
                              colorScheme,
                              isFree: cart.isFreeDelivery,
                            ),
                            if (cart.couponDiscount > 0) ...[
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Coupon Discount (${cart.appliedCoupon?.code})',
                                '- Rs. ${cart.couponDiscount.toStringAsFixed(0)}',
                                colorScheme,
                                isDiscount: true,
                              ),
                            ],
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Payable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(
                                  'Rs. ${cart.total.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Place Order Button
                      CustomButton(
                        text: _isPlacingOrder ? 'Confirming Order...' : 'Confirm & Place Order (Rs. ${cart.total.toStringAsFixed(0)})',
                        isLoading: _isPlacingOrder,
                        onPressed: _isPlacingOrder ? null : () => _submitOrder(cart, auth),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ColorScheme colorScheme, {bool isDiscount = false, bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13.5)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            color: isDiscount || isFree ? Colors.green : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
