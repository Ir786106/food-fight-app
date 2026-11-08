import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';

class CheckoutCancelled implements Exception {
  const CheckoutCancelled();
}

/// Persists an idempotency key before the network request, including retries
/// after the app closes while the server is committing the order.
class CheckoutService {
  static const _pendingKey = 'pending_checkout_v1';

  static Future<OrderModel> place(
    OrderModel order, {
    required String deliveryAreaId,
    String? couponId,
    String? addressId,
    Future<bool> Function(double total)? confirmQuote,
  }) async {
    final payload = <String, dynamic>{
      'branchId': order.branchId,
      'customerName': order.customerName,
      'customerPhone': order.customerPhone,
      'deliveryAddress': order.deliveryAddress,
      'deliveryAreaId': deliveryAreaId,
      'addressId': addressId,
      'paymentMethod': order.paymentMethod,
      'tokensRedeemed': order.tokensUsed,
      'couponId': couponId,
      'clientTotal': order.total,
      'items': order.items
          .map((line) => {
                'id': line.food.id,
                'quantity': line.quantity,
                'selectedSize':
                    line.selectedVariant?.label ?? line.selectedSize,
                'selectedAddons': line.selectedAddons
                    .map((addon) => {'name': addon.name})
                    .toList(),
                'note': line.note,
              })
          .toList(),
    };
    final fingerprint = sha256
        .convert(utf8.encode(order.customerId + jsonEncode(payload)))
        .toString();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_pendingKey);
    Map<String, dynamic>? pending;
    if (saved != null) {
      try {
        pending = jsonDecode(saved) as Map<String, dynamic>;
      } catch (_) {}
    }
    final isRetry = pending?['fingerprint'] == fingerprint &&
        pending?['requestId'] is String;
    var acceptedTotal = order.total;
    if (isRetry) {
      acceptedTotal =
          (pending?['acceptedTotal'] as num?)?.toDouble() ?? order.total;
    } else if (confirmQuote != null) {
      final quote = await FirebaseFunctions.instance
          .httpsCallable('quoteOrder')
          .call(payload);
      final quoteData = (quote.data as Map)['data'] as Map;
      acceptedTotal = (quoteData['total'] as num).toDouble();
      if (!await confirmQuote(acceptedTotal)) throw const CheckoutCancelled();
    }

    final requestId = isRetry
        ? pending!['requestId'] as String
        : DateTime.now().microsecondsSinceEpoch.toString() +
            fingerprint.substring(0, 16);
    final persisted = await prefs.setString(
        _pendingKey,
        jsonEncode({
          'fingerprint': fingerprint,
          'requestId': requestId,
          'acceptedTotal': acceptedTotal,
        }));
    if (!persisted) {
      throw StateError('Unable to save checkout for a safe retry.');
    }
    final response =
        await FirebaseFunctions.instance.httpsCallable('placeOrder').call({
      ...payload,
      'clientTotal': acceptedTotal,
      'requestId': requestId,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    // JSON normalization converts nested callable maps for existing model parsers.
    return OrderModel.fromJson(
        jsonDecode(jsonEncode(data['order'])) as Map<String, dynamic>);
  }

  static Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
  }
}
