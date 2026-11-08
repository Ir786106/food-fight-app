import '../../core/localization/app_language.dart';
import 'package:food_fight/core/utils/app_insets.dart';
import 'package:food_fight/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_area_provider.dart';
import '../../services/checkout_service.dart';
import '../../models/delivery_area_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/network_image_view.dart';
import '../../core/responsive/responsive.dart';
import '../../widgets/custom_button.dart';
import '../../models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/branch_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  String _selectedAddressLabel = 'Home';
  String? _selectedAddressId;
  static const _selectedPayment = 'Cash on Delivery';
  bool _isPlacingOrder = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<AddressProvider>().watchAddresses(user.id);
      }
      _initialized = true;
    }

    // Pre-fill address from saved addresses (only if not yet set by user)
    if (_addressCtrl.text.isEmpty) {
      final addressProvider = context.read<AddressProvider>();
      final addresses = addressProvider.addresses;
      if (addresses.isNotEmpty) {
        final defaultOrFirst =
            addressProvider.defaultAddress ?? addresses.first;
        _selectedAddressLabel = defaultOrFirst.label;
        _selectedAddressId = defaultOrFirst.id;
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
    if (_isPlacingOrder) return;
    final user = auth.currentUser;
    if (user == null) {
      Navigator.of(context).pushNamed('/login');
      return;
    }
    final address = _addressCtrl.text.trim();
    final branches = context.read<BranchProvider>();
    final branch = branches.selectedBranch;
    if (address.length < 8 || branch == null || cart.selectedArea == null) {
      AppSnackbar.showError(
          context, 'Choose a kitchen, delivery area and complete address.');
      return;
    }
    final phone = user.phone.replaceAll(RegExp(r'[\s()-]'), '');
    if (!RegExp(r'^(03\d{9}|\+923\d{9})$').hasMatch(phone)) {
      AppSnackbar.showError(context,
          'Add a valid mobile number in your profile before checkout.');
      return;
    }
    if (branches.isOutOfDeliveryArea) {
      AppSnackbar.showError(
          context, 'Choose an address within this kitchen’s delivery area.');
      return;
    }
    final saved = context
        .read<AddressProvider>()
        .addresses
        .where((a) => a.id == _selectedAddressId && a.details == address)
        .firstOrNull;
    if (saved?.latitude != null &&
        saved?.longitude != null &&
        branch.distanceToKm(saved!.latitude!, saved.longitude!) >
            branch.effectiveRadiusKm) {
      AppSnackbar.showError(
          context, 'This address is outside the kitchen’s delivery coverage.');
      return;
    }
    setState(() => _isPlacingOrder = true);
    try {
      final order = await cart.placeOrder(
          customerId: user.id,
          customerName: user.name,
          customerPhone: phone,
          deliveryAddress: address,
          paymentMethod: _selectedPayment,
          paymentStatus: 'pending',
          restaurantName: branch.name,
          branchId: cart.branchId ?? branch.id,
          addressId: saved?.id,
          confirmQuote: (total) async {
            if (!mounted) return false;
            return await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(context.tr('Confirm cash on delivery')),
                    content: Text(
                      dialogContext.tr('Pay PKR {amount} when your order arrives.')
                          .replaceFirst('{amount}', total.toStringAsFixed(2)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(context.tr('Back')),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(context.tr('Confirm order')),
                      ),
                    ],
                  ),
                ) ??
                false;
          });
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/order-success', (route) => route.settings.name == '/home',
          arguments: order);
    } on CheckoutCancelled {
      return;
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.showError(
          context,
          error is FirebaseFunctionsException
              ? error.message ?? 'Unable to place your order. Please retry.'
              : error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final areaProvider = context.watch<DeliveryAreaProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final branchProv = context.watch<BranchProvider>();
    final deliveryAreas = areaProvider.activeAreas;
    final addresses = addressProvider.addresses;
    final activeBranches = branchProv.activeBranches;
    final currentBranch = activeBranches
            .where(
                (b) => b.id == (cart.branchId ?? branchProv.selectedBranch?.id))
            .firstOrNull ??
        branchProv.selectedBranch;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Automatically set default area if not yet selected
    if (deliveryAreas.isNotEmpty && cart.selectedArea == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cart.setDeliveryArea(deliveryAreas.first);
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr('Checkout')),
        elevation: 0,
      ),
      body: SafeArea(
        child: areaProvider.isLoading && deliveryAreas.isEmpty
            ? const LoadingIndicator(message: 'Loading delivery coverage...')
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 840;
                  final leftPane = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 0. Selected Preparing Branch Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth: (context.screenWidth - 70)
                                          .clamp(140.0, 400.0)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryYellow
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.storefront_rounded,
                                          color: AppColors.primaryYellow,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              context.tr('Preparing Branch'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                            Text(
                                              currentBranch?.name ??
                                                  'Select your area',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryYellow
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    branchProv
                                        .getDeliveryLabel()
                                        .split('•')
                                        .last
                                        .trim(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.brandMaroon,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (currentBranch != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      currentBranch.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      context.tr('Active'),
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // 1. Saved Address Selector as Chips/Cards (Home, Work, +Add new)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('Delivery Address'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () async {
                              final res = await Navigator.of(context)
                                  .pushNamed('/add-address');
                              if (res is AddressModel) {
                                setState(() {
                                  _selectedAddressLabel = res.label;
                                  _selectedAddressId = res.id;
                                  _addressCtrl.text = res.details;
                                });
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: isDark
                                      ? AppColors.brandYellow
                                      : AppColors.amberDark,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.tr('Add New'),
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.brandYellow
                                        : AppColors.amberDark,
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
                              final isSelected =
                                  _selectedAddressLabel == addr.label;
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
                                    _selectedAddressId = addr.id;
                                    _addressCtrl.text = addr.details;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.brandYellow
                                        : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.yellowPressed
                                          : colorScheme.outlineVariant
                                              .withValues(alpha: 0.6),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? AppColors.brandYellow
                                                .withValues(alpha: 0.35)
                                            : Colors.black.withValues(
                                                alpha: isDark ? 0.25 : 0.04),
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
                                            : (isDark
                                                ? AppColors.brandYellow
                                                : AppColors.brandMaroon),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        addr.label,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.onYellow
                                              : colorScheme.onSurface,
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
                                final res = await Navigator.of(context)
                                    .pushNamed('/add-address');
                                if (res is AddressModel) {
                                  setState(() {
                                    _selectedAddressLabel = res.label;
                                    _selectedAddressId = res.id;
                                    _addressCtrl.text = res.details;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.6),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add,
                                        color: colorScheme.onSurfaceVariant,
                                        size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      context.tr('Add Address'),
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
                          hintText:
                              'House / Apartment #, Street, Block, Nearby Landmark...',
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: isDark
                                ? AppColors.brandYellow
                                : AppColors.brandMaroon,
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: colorScheme.outlineVariant),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.25 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<DeliveryAreaModel>(
                              isExpanded: true,
                              dropdownColor: colorScheme.surface,
                              value: (cart.selectedArea != null &&
                                      deliveryAreas.contains(cart.selectedArea))
                                  ? cart.selectedArea
                                  : (deliveryAreas.isNotEmpty
                                      ? deliveryAreas.first
                                      : null),
                              items: deliveryAreas.map((area) {
                                return DropdownMenuItem(
                                  value: area,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          area.name,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Rs. ${area.deliveryCharge.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.brandYellow
                                              : AppColors.brandMaroon,
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
                            color: isDark
                                ? AppColors.darkYellowSoft
                                : AppColors.yellowSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  AppColors.brandYellow.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Standard Express Delivery: ${cart.deliveryFee == 0 ? "FREE" : "Rs. ${cart.deliveryFee.toInt()}"} (${cart.selectedArea?.name ?? currentBranch?.city ?? "Citywide"})',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.brandYellow
                                  : AppColors.brandMaroon,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // 3. Payment Method Selector as Radio List
                      Text(
                        context.tr('Payment Method'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.payments_outlined),
                        title: Text(context.tr(_selectedPayment)),
                        subtitle: Text(context.tr('Pay in cash when your order arrives')),
                      ),
                    ],
                  );

                  final rightPane = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.35 : 0.05),
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
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.4),
                          ),
                          itemBuilder: (context, idx) {
                            final item = cart.items[idx];
                            final hasVariant = item.selectedVariant != null ||
                                (item.selectedSize != null &&
                                    item.selectedSize!.isNotEmpty);
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: isDark
                                            ? AppColors.brandYellow
                                            : AppColors.brandMaroon,
                                      ),
                                    ),
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
                        context.tr('Fee Breakdown'),
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
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.35 : 0.05),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _summaryRow(
                              context,
                              context.tr('Subtotal ({count} items)').replaceFirst('{count}', cart.itemCount.toString()),
                              'Rs. ${cart.subtotal.toStringAsFixed(0)}',
                            ),
                            const SizedBox(height: 8),
                            _summaryRow(
                              context,
                              cart.selectedArea != null
                                  ? context.tr('Delivery Fee ({area})').replaceFirst('{area}', cart.selectedArea!.name)
                                  : context.tr('Delivery Fee'),
                              cart.isFreeDelivery
                                  ? context.tr('FREE')
                                  : 'Rs. ${cart.deliveryFee.toStringAsFixed(0)}',
                              color: cart.isFreeDelivery
                                  ? AppColors.success
                                  : null,
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
                            Divider(
                                height: 1,
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.5)),
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
                  );

                  if (isWide) {
                    return ResponsiveBox(
                      maxWidth: 1200,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: leftPane),
                            const SizedBox(width: 28),
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  rightPane,
                                  const SizedBox(height: 20),
                                  _buildWidePlaceOrderButton(
                                      cart, auth, isDark, colorScheme),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ResponsiveBox.form(
                    maxWidth: 600,
                    child: SingleChildScrollView(
                      padding: AppInsets.scrollPadding(context,
                          horizontal: 20, top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          leftPane,
                          const SizedBox(height: 24),
                          rightPane,
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),

      // Sticky checkout action bar (only shown on compact/medium when below 840px)
      bottomNavigationBar: (context.screenWidth < 840)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: (context.screenWidth < 360 || context.textScale > 1.2)
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  context.tr('Grand Total'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Rs. ${cart.total.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? AppColors.brandYellow
                                          : AppColors.brandMaroon,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CustomButton(
                            text: _isPlacingOrder
                                ? context.tr('Checking order...')
                                : context.tr('Review order'),
                            isLoading: _isPlacingOrder,
                            icon: Icons.check_circle_outline_rounded,
                            onPressed: _isPlacingOrder
                                ? null
                                : () => _submitOrder(cart, auth),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('Grand Total'),
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
                                  color: isDark
                                      ? AppColors.brandYellow
                                      : AppColors.brandMaroon,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: CustomButton(
                              text: _isPlacingOrder
                                  ? context.tr('Checking order...')
                                  : context.tr('Review order'),
                              isLoading: _isPlacingOrder,
                              icon: Icons.check_circle_outline_rounded,
                              onPressed: _isPlacingOrder
                                  ? null
                                  : () => _submitOrder(cart, auth),
                            ),
                          ),
                        ],
                      ),
              ),
            )
          : null,
    );
  }

  Widget _buildWidePlaceOrderButton(CartProvider cart, AuthProvider auth,
      bool isDark, ColorScheme colorScheme) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  context.tr('Grand Total'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Rs. ${cart.total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.brandYellow
                          : AppColors.brandMaroon,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: _isPlacingOrder ? context.tr('Checking order...') : context.tr('Review order'),
            isLoading: _isPlacingOrder,
            icon: Icons.check_circle_outline_rounded,
            onPressed: _isPlacingOrder ? null : () => _submitOrder(cart, auth),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value,
      {bool isBold = false, Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isBold ? 16 : 13.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
              color:
                  isBold ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: isBold ? 18 : 13.5,
                fontWeight: FontWeight.w900,
                color: color ??
                    (isBold
                        ? (isDark
                            ? AppColors.brandYellow
                            : AppColors.brandMaroon)
                        : colorScheme.onSurface),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
