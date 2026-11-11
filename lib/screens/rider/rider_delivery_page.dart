import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/design_system.dart';
import '../../core/localization/app_language.dart';
import '../../models/order_model.dart';
import '../../providers/rider_provider.dart';

class RiderDeliveryPage extends StatefulWidget {
  const RiderDeliveryPage({
    super.key,
    required this.orderId,
    required this.advance,
    required this.decline,
    required this.fail,
    required this.open,
  });

  final String orderId;
  final Future<void> Function(OrderModel) advance;
  final Future<void> Function(OrderModel) decline;
  final Future<void> Function(OrderModel) fail;
  final Future<void> Function(Uri) open;

  @override
  State<RiderDeliveryPage> createState() => _RiderDeliveryPageState();
}

class _RiderDeliveryPageState extends State<RiderDeliveryPage> {
  Timer? _timer;
  bool _busy = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riders = context.watch<RiderProvider>();
    final matches = [
      ...riders.assignedDeliveries,
      ...riders.completedDeliveries,
      ...riders.cancelledDeliveries,
    ].where((order) => order.id == widget.orderId);
    final order = matches.firstOrNull;
    final offer =
        order?.status == OrderStatus.assigned && order?.riderAcceptedAt == null;
    final remaining =
        offer ? order?.offerExpiresAt?.difference(DateTime.now()) : null;
    final expired = remaining != null && remaining <= Duration.zero;
    if (remaining != null && !expired) {
      _timer ??=
          Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    } else {
      _timer?.cancel();
      _timer = null;
    }
    return Scaffold(
      appBar: AppBar(title: Text(order?.orderNumber ?? context.tr('Delivery'))),
      body: order == null
          ? Center(
              child: Text(context.tr('This delivery is no longer available.')))
          : ListView(
              padding: AppInsets.scrollPadding(context),
              children: [
                StatusChip(
                  label: context.tr(order.status.displayName),
                  tone: switch (order.status) {
                    OrderStatus.delivered => StatusTone.success,
                    OrderStatus.cancelled => StatusTone.error,
                    _ when offer => StatusTone.warning,
                    _ => StatusTone.active,
                  },
                ),
                if (remaining != null)
                  Text(expired
                      ? context.tr('Offer expired')
                      : context.tr('{seconds}s').replaceFirst(
                            '{seconds}',
                            MaterialLocalizations.of(context)
                                .formatDecimal(remaining.inSeconds + 1),
                          )),
                ListTile(
                    title: Text(order.restaurantName),
                    subtitle: Text(order.deliveryAddress)),
                ListTile(
                  title: Text(order.customerName),
                  subtitle: Text(order.customerPhone, textDirection: TextDirection.ltr),
                  trailing: order.customerPhone.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.tr('Call'),
                          onPressed: () => widget.open(
                              Uri(scheme: 'tel', path: order.customerPhone)),
                          icon: const Icon(Icons.phone_outlined),
                        ),
                ),
                for (final line in order.items)
                  ListTile(
                      title: Text(line.displayName),
                      trailing: Text('×${line.quantity}')),
                AppCard(
                    child: ListTile(
                  title: Text(context.tr(order.paymentStatus == 'paid'
                      ? 'Paid'
                      : 'Amount to collect')),
                  subtitle: Text(context.tr(order.paymentMethod)),
                  trailing: Text('${context.tr('Rs.')} ${order.total.toStringAsFixed(2)}'),
                )),
                if (order.cancellationReason?.isNotEmpty == true)
                  ListTile(title: Text(order.cancellationReason!)),
                AppButton(
                  label: context.tr('Navigate'),
                  style: AppButtonStyle.secondary,
                  onPressed: () => widget.open(Uri.https(
                      'www.google.com',
                      '/maps/search/',
                      {'api': '1', 'query': order.deliveryAddress})),
                ),
                if (!order.status.isTerminal) ...[
                  AppButton(
                    label: context.tr(offer
                        ? 'Accept'
                        : switch (order.status) {
                            OrderStatus.assigned => 'Picked up',
                            OrderStatus.pickedUp => 'On the way',
                            _ => 'Delivered',
                          }),
                    loadingLabel: _busy ? context.tr('Updating…') : null,
                    onPressed: !riders.isOnline || expired
                        ? null
                        : () => _run(() => widget.advance(order)),
                  ),
                  AppButton(
                    label: context.tr(offer ? 'Decline' : 'Report failure'),
                    style: AppButtonStyle.ghost,
                    onPressed: _busy || expired
                        ? null
                        : () => _run(() =>
                            offer ? widget.decline(order) : widget.fail(order)),
                  ),
                ],
              ],
            ),
    );
  }
}
