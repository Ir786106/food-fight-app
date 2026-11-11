const fs = require('node:fs');
function edit(file, fn) { fs.writeFileSync(file, fn(fs.readFileSync(file,'utf8').replace(/\r\n/g,'\n'))); }
edit('lib/services/order_service.dart', s => {
  s = s.replace("import 'branch_service.dart';", "import 'package:firebase_auth/firebase_auth.dart';");
  for (const line of ["import 'loyalty_service.dart';", "import 'notification_service.dart';", "import 'package:food_fight/models/notification_model.dart';"]) s = s.replace(line+'\n','');
  s = s.slice(0,s.indexOf('  /// Place a new order')) + s.slice(s.indexOf('  /// Watch orders for a specific customer'));
  s = s.replace("status.toLowerCase().replaceAll(' ', '')", 'OrderStatus.fromString(status).name');
  const start = s.indexOf('  /// Update order status');
  const end = s.indexOf('  /// Cancel order by customer');
  s = s.slice(0,start) + `  /// Validates and records every transition in the same transaction.
  static Future<void> updateOrderStatus(String orderId, OrderStatus newStatus,
      {String? cancellationReason}) async {
    final ref = _collection.doc(orderId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('Order not found');
      final order = OrderModel.fromJson(Map<String, dynamic>.from(snapshot.data() as Map));
      if (order.status == newStatus) return;
      if (!order.status.canTransitionTo(newStatus)) {
        throw StateError('This order status changed. Refresh before continuing.');
      }
      if (newStatus == OrderStatus.assigned) throw StateError('Choose an online rider to assign this order.');
      if (newStatus == OrderStatus.pickedUp && order.riderAcceptedAt == null) {
        throw StateError('Accept the delivery before pickup.');
      }
      if (newStatus == OrderStatus.cancelled && (cancellationReason?.trim().isEmpty ?? true)) {
        throw StateError('Please provide a cancellation reason.');
      }
      final now = DateTime.now();
      transaction.update(ref, {
        'status': newStatus.name, 'updatedAt': now.millisecondsSinceEpoch,
        if (newStatus == OrderStatus.delivered) 'deliveredAt': now.millisecondsSinceEpoch,
        if (cancellationReason != null) 'cancellationReason': cancellationReason.trim(),
        'statusHistory': FieldValue.arrayUnion([OrderStatusEvent(
          status: newStatus, timestamp: now,
          actorId: FirebaseAuth.instance.currentUser?.uid ?? '',
          reason: cancellationReason).toJson()]),
      });
    });
    // Trusted server triggers own notifications, reward credit and refunds.
  }

` + s.slice(end);
  return s;
});
edit('lib/services/loyalty_service.dart', s => s.slice(0,s.indexOf('  /// Credit welcome bonus')) + `  /// Reward balances are owned by trusted server transactions.
  Future<void> creditWelcomeBonus(String userId, {int amount = 50}) async {
    if (userId.isEmpty) return;
    await FirebaseFunctions.instance.httpsCallable('claimWelcomeBonus').call();
  }
}
`);
edit('lib/services/loyalty_service.dart', s => "import 'package:cloud_functions/cloud_functions.dart';\n" + s);
edit('lib/providers/loyalty_provider.dart', s => {
  const start = s.indexOf('  Future<bool> redeemTokens(');
  return start < 0 ? s : s.slice(0,start) + '}\n';
});
edit('lib/screens/checkout/checkout_screen.dart', s => {
  s = s.replace("import '../../providers/loyalty_provider.dart';", "import 'package:cloud_functions/cloud_functions.dart';");
  s = s.replace("  String _selectedAddressLabel = 'Home';", "  String _selectedAddressLabel = 'Home';\n  String? _selectedAddressId;");
  s = s.replace('final addressText = _addressCtrl.text.trim();', 'if (_isPlacingOrder) return;\n    final addressText = _addressCtrl.text.trim();');
  s = s.replace("if (addressText.isEmpty)", "if (addressText.length < 8)");
  s = s.replace("final paymentStatus = _selectedPayment == 'Cash on Delivery' ? 'pending' : 'paid';", "const paymentStatus = 'pending';");
  s = s.replace('final selectedBranch = branchProv.selectedBranch;', `final selectedBranch = branchProv.selectedBranch;
      if (selectedBranch == null || cart.selectedArea == null) {
        throw StateError('Choose your kitchen and delivery area.');
      }
      if (!RegExp(r'^(03\\d{9}|\\+923\\d{9})$').hasMatch(customerPhone.replaceAll(RegExp(r'[\\s()-]'), ''))) {
        throw StateError('Add a valid mobile number in your profile before checkout.');
      }`);
  s = s.replace('a.label == _selectedAddressLabel', 'a.id == _selectedAddressId && a.details == addressText');
  s = s.replace('branchId: branchId,\n      );', 'branchId: branchId,\n        addressId: _selectedAddressId,\n      );');
  const start = s.indexOf('      // Redeem loyalty tokens atomically');
  const end = s.indexOf('      if (!mounted) return;',start);
  s = s.slice(0,start) + s.slice(end);
  s = s.replace("Text('Error placing order: $e')", "Text(e is FirebaseFunctionsException ? (e.message ?? 'Unable to place order. Please retry.') : e.toString().replaceFirst('Bad state: ', ''))");
  s = s.replace('    }\n  }\n\n  @override\n  Widget build', '    } finally {\n      if (mounted) setState(() => _isPlacingOrder = false);\n    }\n  }\n\n  @override\n  Widget build');
  s = s.replaceAll('_selectedAddressLabel = defaultOrFirst.label;', '_selectedAddressLabel = defaultOrFirst.label;\n        _selectedAddressId = defaultOrFirst.id;');
  s = s.replaceAll('_selectedAddressLabel = addr.label;', '_selectedAddressLabel = addr.label;\n                                    _selectedAddressId = addr.id;');
  s = s.replaceAll('_selectedAddressLabel = res.label;', '_selectedAddressLabel = res.label;\n                                  _selectedAddressId = res.id;');
  return s;
});
