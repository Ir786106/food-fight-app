import '../../core/localization/app_language.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/design_system.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rider_provider.dart';
import '../../services/order_service.dart';
import '../../services/rider_location_service.dart';
import '../../services/rider_service.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});
  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  late RiderProvider _riders;
  String? _riderId;
  StreamSubscription<Position>? _positions;
  Set<String> _broadcastOrders = {};
  final Set<String> _busy = {};
  bool _startingLocation = false;
  bool _changingOnline = false;
  String? _locationError;
  int _locationGeneration = 0;
  DateTime? _lastBack;

  @override
  void initState() {
    super.initState();
    _riders = context.read<RiderProvider>();
    _riderId = context.read<AuthProvider>().currentUser?.id;
    _riders.addListener(_syncTracking);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _riderId != null) _riders.watchRiderDeliveries(_riderId!);
    });
  }

  void _syncTracking() {
    if (!mounted) return;
    final desired = _riders.isOnline ? _riders.assignedDeliveries
        .where((order) => order.status.isBroadcasting).map((order) => order.id).toSet() : <String>{};
    for (final id in _broadcastOrders.difference(desired)) {
      RiderLocationService.stopBroadcasting(orderId: id, riderId: _riderId!);
    }
    _broadcastOrders = desired;
    if (desired.isEmpty) {
      _locationGeneration++;
      _positions?.cancel();
      _positions = null;
    } else if (_positions == null && !_startingLocation && _locationError == null) {
      _startLocation();
    }
  }

  Future<void> _startLocation() async {
    if (_startingLocation) return;
    _startingLocation = true;
    final generation = ++_locationGeneration;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Turn on device location to share your delivery position.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw StateError('Allow location access to share your delivery position.');
      }
      if (!mounted || generation != _locationGeneration || _broadcastOrders.isEmpty) return;
      final LocationSettings settings = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(accuracy: LocationAccuracy.high, distanceFilter: 20,
            intervalDuration: const Duration(seconds: 10),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Food Fight delivery',
              notificationText: 'Sharing your position during active deliveries',
              enableWakeLock: true))
        : const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 20);
      _positions = Geolocator.getPositionStream(locationSettings: settings).listen((position) {
        if (!mounted || generation != _locationGeneration) return;
        for (final id in _broadcastOrders.toList()) {
          RiderLocationService.updateOrderRiderLocation(orderId: id, riderId: _riderId!,
            latitude: position.latitude, longitude: position.longitude,
            heading: position.heading, speed: position.speed);
        }
      }, onError: (_) {
        if (mounted) setState(() => _locationError = 'Location updates stopped. Check GPS and retry.');
        _positions?.cancel(); _positions = null;
      });
      setState(() => _locationError = null);
    } catch (error) {
      if (mounted) setState(() => _locationError = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      _startingLocation = false;
    }
  }

  @override
  void dispose() {
    _locationGeneration++;
    _riders.removeListener(_syncTracking);
    _positions?.cancel();
    for (final id in _broadcastOrders) {
      RiderLocationService.stopBroadcasting(orderId: id, riderId: _riderId!);
    }
    super.dispose();
  }

  Future<void> _advance(OrderModel order) async {
    if (_busy.contains(order.id) || !_riders.isOnline) return;
    setState(() => _busy.add(order.id));
    try {
      if (order.status == OrderStatus.assigned && order.riderAcceptedAt == null) {
        await RiderService.acceptDelivery(order.id);
      } else {
        final next = order.status.nextStatus;
        if (next == null) return;
        if (next == OrderStatus.delivered) {
          final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            title: Text(context.tr('Confirm delivery')),
            content: Text(order.paymentStatus == 'paid' ? 'Have you handed over the order?'
              : 'Confirm handover and collection of Rs. ${order.total.toStringAsFixed(0)}.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Back'))),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('Delivered')))],
          ));
          if (confirmed != true) return;
        }
        await OrderService.updateOrderStatus(
          order.id,
          next,
          codCollected: next == OrderStatus.delivered && order.paymentStatus != 'paid',
        );
      }
    } catch (error) {
      if (mounted) AppSnackbar.showError(context, error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  Future<void> _decline(OrderModel order) async {
    if (_busy.contains(order.id)) return;
    setState(() => _busy.add(order.id));
    try {
      await RiderService.declineDelivery(order.id);
    } catch (error) {
      if (mounted) AppSnackbar.showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  Future<void> _fail(OrderModel order) async {
    final reason = TextEditingController();
    final accepted = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(context.tr('Delivery failed')),
      content: TextField(controller: reason, maxLength: 500, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Explain what happened')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Back'))),
        FilledButton(onPressed: () { if (reason.text.trim().length >= 3) Navigator.pop(ctx, true); },
          child: Text(context.tr('Report failure')))],
    ));
    final text = reason.text.trim(); reason.dispose();
    if (accepted != true || !mounted) return;
    try { await OrderService.updateOrderStatus(order.id, OrderStatus.cancelled, cancellationReason: text); }
    catch (error) { if (mounted) AppSnackbar.showError(context, error.toString()); }
  }

  Future<void> _open(Uri uri) async {
    try { if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw StateError('No application available'); }
    catch (_) { if (mounted) AppSnackbar.showError(context, 'Unable to open this action on your device.'); }
  }

  @override
  Widget build(BuildContext context) {
    final riders = context.watch<RiderProvider>();
    final today = DateTime.now();
    final deliveredToday = riders.completedDeliveries.where((order) {
      final date = order.deliveredAt;
      return order.status == OrderStatus.delivered && date != null &&
        date.year == today.year && date.month == today.month && date.day == today.day;
    }).length;
    return PopScope(canPop: Navigator.of(context).canPop(), onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      if (MediaQuery.viewInsetsOf(context).bottom > 0) { FocusScope.of(context).unfocus(); return; }
      final now = DateTime.now();
      if (_lastBack != null && now.difference(_lastBack!) < const Duration(seconds: 2)) {
        SystemNavigator.pop();
      } else {
        _lastBack = now; AppSnackbar.showInfo(context, 'Press back again to exit');
      }
    }, child: DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: Text(context.tr('Deliveries')), actions: [
        IconButton(tooltip: context.tr('Notifications'), onPressed: () => Navigator.pushNamed(context, '/notifications'),
          icon: const Icon(Icons.notifications_outlined)),
        IconButton(tooltip: context.tr('Sign Out'), onPressed: () => context.read<AuthProvider>().signOut(),
          icon: const Icon(Icons.logout)),
      ], bottom: const TabBar(tabs: [Tab(text: 'Active'), Tab(text: 'Completed')])),
      body: Column(children: [
        SwitchListTile(title: Text(context.tr(riders.isOnline ? 'Online' : 'Offline')),
          subtitle: Text('$deliveredToday delivered today • ${riders.assignedDeliveries.length} active'),
          value: riders.isOnline, onChanged: _changingOnline || riders.currentRider == null ? null : (value) async {
            setState(() => _changingOnline = true);
            final ok = await riders.toggleOnline(_riderId!, value);
            if (!mounted) return;
            setState(() => _changingOnline = false);
            if (!ok && context.mounted) AppSnackbar.showError(context, riders.errorMessage ?? 'Could not change availability.');
          }),
        if (_locationError != null) ListTile(leading: const Icon(Icons.location_off_outlined),
          title: Text(_locationError!), trailing: TextButton(onPressed: () {
            setState(() => _locationError = null); _syncTracking();
          }, child: Text(context.tr('Retry')))),
        if (riders.errorMessage != null) Padding(padding: DesignSystem.screenPadding,
          child: Text(riders.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        if (riders.isLoading) const LinearProgressIndicator(),
        Expanded(child: TabBarView(children: [
          _orders(riders.assignedDeliveries, false),
          _orders(riders.completedDeliveries, true),
        ])),
      ]),
    )));
  }

  Widget _orders(List<OrderModel> orders, bool completed) {
    if (orders.isEmpty) {
      return EmptyStateView(icon: Icons.delivery_dining,
      title: completed ? 'No completed deliveries' : 'No active deliveries',
      description: completed ? 'Your completed deliveries will appear here.'
          : 'Go online to receive assignments from your kitchen.');
    }
    return ListView.separated(padding: AppInsets.scrollPadding(context),
      itemCount: orders.length, separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space8),
      itemBuilder: (context, index) {
        final order = orders[index];
        final offered = order.status == OrderStatus.assigned && order.riderAcceptedAt == null;
        final label = offered
            ? 'Accept' : order.status == OrderStatus.assigned ? 'Picked up'
            : order.status == OrderStatus.pickedUp ? 'On the way' : 'Delivered';
        return Card(child: Padding(padding: DesignSystem.cardPadding, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order.orderNumber, style: Theme.of(context).textTheme.titleMedium),
            Text(context.tr(order.status.displayName), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppDimens.space8),
            Text(order.customerName), Text(order.deliveryAddress),
            Text(order.items.map((line) => '${line.quantity} × ${line.displayName}').join(', ')),
            const SizedBox(height: AppDimens.space8),
            Text((order.paymentStatus == 'paid' ? 'Paid: Rs. ' : 'Collect: Rs. ') + order.total.toStringAsFixed(0)),
            Wrap(spacing: AppDimens.space8, children: [
              if (order.customerPhone.isNotEmpty) TextButton.icon(
                onPressed: () => _open(Uri(scheme: 'tel', path: order.customerPhone)),
                icon: const Icon(Icons.phone_outlined), label: Text(context.tr('Call'))),
              TextButton.icon(onPressed: () => _open(Uri.https('www.google.com', '/maps/search/',
                {'api': '1', 'query': order.deliveryAddress})),
                icon: const Icon(Icons.navigation_outlined), label: Text(context.tr('Navigate'))),
              if (!completed) ...[
                FilledButton(onPressed: !_riders.isOnline || _busy.contains(order.id) ? null : () => _advance(order),
                  child: Text(context.tr(_busy.contains(order.id) ? 'Updating…' : label))),
                TextButton(
                  onPressed: _busy.contains(order.id) ? null : () {
                    if (offered) {
                      _decline(order);
                    } else {
                      _fail(order);
                    }
                  },
                  child: Text(context.tr(offered ? 'Decline' : 'Failed delivery')),
                ),
              ],
            ]),
          ],
        )));
      });
  }
}
