const fs = require('node:fs');
const p = 'lib/screens/checkout/checkout_screen.dart';
let s = fs.readFileSync(p,'utf8');
const build = s.indexOf('  Widget build(BuildContext context)');
const end = s.indexOf('\n}\n', build) + 3;
if(end < build) throw Error('Class end not found');
s = s.slice(0,end);
const start = s.indexOf('  Future<void> _submitOrder(');
const after = s.lastIndexOf('  @override',build);
s = s.slice(0,start) + `  Future<void> _submitOrder(CartProvider cart, AuthProvider auth) async {
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
      AppSnackbar.showError(context, 'Choose a kitchen, delivery area and complete address.');
      return;
    }
    final phone = user.phone.replaceAll(RegExp(r'[\\s()-]'), '');
    if (!RegExp(r'^(03\\d{9}|\\+923\\d{9})$').hasMatch(phone)) {
      AppSnackbar.showError(context, 'Add a valid mobile number in your profile before checkout.');
      return;
    }
    if (branches.isOutOfDeliveryArea) {
      AppSnackbar.showError(context, 'Choose an address within this kitchen’s delivery area.');
      return;
    }
    final saved = context.read<AddressProvider>().addresses.where((a) =>
        a.id == _selectedAddressId && a.details == address).firstOrNull;
    if (saved?.latitude != null && saved?.longitude != null &&
        branch.distanceToKm(saved!.latitude!, saved.longitude!) > branch.effectiveRadiusKm) {
      AppSnackbar.showError(context, 'This address is outside the kitchen’s delivery coverage.');
      return;
    }
    setState(() => _isPlacingOrder = true);
    try {
      final order = await cart.placeOrder(customerId: user.id,
        customerName: user.name, customerPhone: phone,
        deliveryAddress: address, paymentMethod: _selectedPayment,
        paymentStatus: 'pending', restaurantName: branch.name,
        branchId: cart.branchId ?? branch.id, addressId: saved?.id);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/order-success', (route) => route.settings.name == '/home', arguments: order);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.showError(context, error is FirebaseFunctionsException
          ? error.message ?? 'Unable to place your order. Please retry.'
          : error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

` + s.slice(after);
fs.writeFileSync(p,s);
