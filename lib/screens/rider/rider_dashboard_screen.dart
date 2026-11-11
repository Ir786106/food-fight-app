import '../../core/localization/app_language.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/design_system/design_system.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rider_provider.dart';
import '../../services/order_service.dart';
import '../../services/rider_location_service.dart';
import '../../services/rider_service.dart';
import 'rider_delivery_page.dart';

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
  int _destination = 0;
  int _earningsPeriod = 0;
  String _search = '';
  DateTimeRange? _dates;

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
    final desired = _riders.isOnline
        ? _riders.assignedDeliveries
            .where((order) => order.status.isBroadcasting)
            .map((order) => order.id)
            .toSet()
        : <String>{};
    for (final id in _broadcastOrders.difference(desired)) {
      RiderLocationService.stopBroadcasting(orderId: id, riderId: _riderId!);
    }
    _broadcastOrders = desired;
    if (desired.isEmpty) {
      _locationGeneration++;
      _positions?.cancel();
      _positions = null;
    } else if (_positions == null &&
        !_startingLocation &&
        _locationError == null) {
      _startLocation();
    }
  }

  Future<void> _startLocation() async {
    if (_startingLocation) return;
    _startingLocation = true;
    final generation = ++_locationGeneration;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError(
            'Turn on device location to share your delivery position.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(
            'Allow location access to share your delivery position.');
      }
      if (!mounted ||
          generation != _locationGeneration ||
          _broadcastOrders.isEmpty) return;
      final LocationSettings settings = !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 20,
              intervalDuration: const Duration(seconds: 10),
              foregroundNotificationConfig: ForegroundNotificationConfig(
                  notificationTitle: context.tr('Food Fight delivery'),
                  notificationText: context.tr(
                      'Sharing your position during active deliveries'),
                  enableWakeLock: true))
          : const LocationSettings(
              accuracy: LocationAccuracy.high, distanceFilter: 20);
      _positions = Geolocator.getPositionStream(locationSettings: settings)
          .listen((position) {
        if (!mounted || generation != _locationGeneration) return;
        for (final id in _broadcastOrders.toList()) {
          RiderLocationService.updateOrderRiderLocation(
              orderId: id,
              riderId: _riderId!,
              latitude: position.latitude,
              longitude: position.longitude,
              heading: position.heading,
              speed: position.speed);
        }
      }, onError: (_) {
        if (mounted)
          setState(() => _locationError =
              'Location updates stopped. Check GPS and retry.');
        _positions?.cancel();
        _positions = null;
      });
      setState(() => _locationError = null);
    } catch (error) {
      if (mounted)
        setState(() =>
            _locationError = error.toString().replaceFirst('Bad state: ', ''));
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
    if (_busy.contains(order.id) ||
        !_riders.isOnline ||
        (_isOffer(order) && _offerExpired(order))) return;
    setState(() => _busy.add(order.id));
    try {
      if (order.status == OrderStatus.assigned &&
          order.riderAcceptedAt == null) {
        await RiderService.acceptDelivery(order.id);
      } else {
        final next = order.status.nextStatus;
        if (next == null) return;
        if (next == OrderStatus.delivered) {
          final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                    title: Text(context.tr('Confirm delivery')),
                    content: Text(order.paymentStatus == 'paid'
                        ? ctx.tr('Have you handed over the order?')
                        : ctx.tr('Confirm handover and collection of {amount}.')
                            .replaceFirst('{amount}',
                                '${ctx.tr('Rs.')} ${order.total.toStringAsFixed(0)}')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(context.tr('Back'))),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(context.tr('Delivered')))
                    ],
                  ));
          if (confirmed != true) return;
        }
        await OrderService.updateOrderStatus(
          order.id,
          next,
          codCollected:
              next == OrderStatus.delivered && order.paymentStatus != 'paid',
        );
      }
    } catch (error) {
      if (mounted)
        AppSnackbar.showError(
            context, error.toString().replaceFirst('Bad state: ', ''));
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
    final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(context.tr('Delivery failed')),
              content: TextField(
                  controller: reason,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: InputDecoration(
                      labelText: ctx.tr('Explain what happened'))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(context.tr('Back'))),
                FilledButton(
                    onPressed: () {
                      if (reason.text.trim().length >= 3)
                        Navigator.pop(ctx, true);
                    },
                    child: Text(context.tr('Report failure')))
              ],
            ));
    final text = reason.text.trim();
    reason.dispose();
    if (accepted != true || !mounted) return;
    try {
      await OrderService.updateOrderStatus(order.id, OrderStatus.cancelled,
          cancellationReason: text);
    } catch (error) {
      if (mounted) AppSnackbar.showError(context, error.toString());
    }
  }

  Future<void> _open(Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
        throw StateError('No application available');
    } catch (_) {
      if (mounted)
        AppSnackbar.showError(
            context, context.tr('Unable to open this action on your device.'));
    }
  }

  bool _isOffer(OrderModel order) =>
      order.status == OrderStatus.assigned && order.riderAcceptedAt == null;

  bool _offerExpired(OrderModel order) =>
      order.offerExpiresAt?.isAfter(DateTime.now()) == false;

  @override
  Widget build(BuildContext context) {
    final riders = context.watch<RiderProvider>();
    final active =
        riders.assignedDeliveries.where((order) => !_isOffer(order)).toList();
    final offers = riders.isOnline
        ? riders.assignedDeliveries.where(_isOffer).toList()
        : <OrderModel>[];
    final page = switch (_destination) {
      0 => _home(riders, active, offers),
      1 => _orderTabs(offers, active, riders),
      2 => _earnings(riders),
      _ => _profile(riders),
    };
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_destination != 0) {
          setState(() {
            _destination = 0;
            _search = '';
          });
          return;
        }
        final now = DateTime.now();
        if (_lastBack != null &&
            now.difference(_lastBack!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
        } else {
          _lastBack = now;
          AppSnackbar.showInfo(context, context.tr('Press back again to exit'));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context
              .tr(['Home', 'Orders', 'Earnings', 'Profile'][_destination])),
          actions: [
            IconButton(
              tooltip: context.tr('Notifications'),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _destination,
          onDestinationSelected: (index) => setState(() {
            _destination = index;
            if (index != 1) _search = '';
          }),
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                label: context.tr('Home')),
            NavigationDestination(
                icon: const Icon(Icons.receipt_long_outlined),
                label: context.tr('Orders')),
            NavigationDestination(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: context.tr('Earnings')),
            NavigationDestination(
                icon: const Icon(Icons.person_outline),
                label: context.tr('Profile')),
          ],
        ),
        body: Column(
          children: [
            if (_locationError != null)
              ListTile(
                leading: const Icon(Icons.location_off_outlined),
                title: Text(context.tr(_locationError!)),
                trailing: AppButton(
                  label: context.tr('Retry'),
                  style: AppButtonStyle.ghost,
                  onPressed: () {
                    setState(() => _locationError = null);
                    _syncTracking();
                  },
                ),
              ),
            if (riders.errorMessage != null)
              ListTile(
                title: Text(context.tr(riders.errorMessage!)),
                trailing: AppButton(
                  label: context.tr('Retry'),
                  style: AppButtonStyle.ghost,
                  onPressed: _riderId == null
                      ? null
                      : () => riders.watchRiderDeliveries(_riderId!),
                ),
              ),
            Expanded(
              child: riders.isLoading
                  ? ListView.builder(
                      itemCount: 3,
                      padding: DesignSystem.screenPadding,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: DesignSystem.space16),
                        child: ShimmerLoader(height: 96),
                      ),
                    )
                  : page,
            ),
          ],
        ),
      ),
    );
  }

  Widget _home(
      RiderProvider riders, List<OrderModel> active, List<OrderModel> offers) {
    final today = DateUtils.dateOnly(DateTime.now());
    final deliveredToday = riders.earningsOrders
        .where((order) => DateUtils.isSameDay(
            (order.deliveredAt ?? order.updatedAt).toLocal(), today))
        .length;
    return ListView(
      padding: AppInsets.scrollPadding(context),
      children: [
        SwitchListTile(
          title: Text(context.tr(riders.isOnline ? 'Online' : 'Offline')),
          value: riders.isOnline,
          onChanged:
              _changingOnline || riders.currentRider == null || _riderId == null
                  ? null
                  : (value) async {
                      setState(() => _changingOnline = true);
                      await riders.toggleOnline(_riderId!, value);
                      if (mounted) setState(() => _changingOnline = false);
                    },
        ),
        if (active.isNotEmpty) ...[
          SectionHeader(title: context.tr('Active delivery')),
          _orderSummary(active.first),
        ],
        AppCard(
            child: ListTile(
          title: Text(context.tr('Deliveries today')),
          trailing: riders.earningsLoading || riders.earningsUnavailable
              ? const Text('—')
              : AppAnimatedCounter(
              value: deliveredToday,
              format: (value) => value.round().toString()),
        )),
        SectionHeader(title: context.tr('Incoming offers')),
        if (offers.isEmpty)
          ListTile(
              title: Text(context.tr(riders.isOnline
                  ? 'No new offers'
                  : 'Go online to receive offers'))),
        for (final order in offers) _orderSummary(order),
      ],
    );
  }

  Widget _orderTabs(
      List<OrderModel> offers, List<OrderModel> active, RiderProvider riders) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(isScrollable: true, tabs: [
            for (final label in ['New', 'Active', 'Completed', 'Cancelled'])
              Tab(text: context.tr(label)),
          ]),
          AppSearchBar(
            hint: context.tr('Search orders'),
            onChanged: (value) =>
                setState(() => _search = value.trim().toLowerCase()),
          ),
          Wrap(children: [
            AppButton(
              style: AppButtonStyle.ghost,
              label: context.tr('Date range'),
              onPressed: _pickDates,
            ),
            if (_dates != null)
              AppButton(
                style: AppButtonStyle.ghost,
                label: context.tr('Clear date range'),
                onPressed: () => setState(() => _dates = null),
              ),
          ]),
          Expanded(
              child: TabBarView(children: [
            _orders(offers, 'No new offers'),
            _orders(active, 'No active deliveries'),
            _orders(riders.completedDeliveries, 'No completed deliveries',
                history: riders),
            _orders(riders.cancelledDeliveries, 'No cancelled deliveries',
                history: riders),
          ])),
        ],
      ),
    );
  }

  Future<void> _pickDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: _dates,
    );
    if (mounted && selected != null) setState(() => _dates = selected);
  }

  Future<void> _refreshOrders() async {
    final riderId = _riderId;
    if (riderId == null) return;
    try {
      await RiderService.refreshRiderOrders(riderId);
    } catch (_) {
      if (mounted)
        AppSnackbar.showError(
            context, context.tr('Unable to refresh deliveries.'));
    }
  }

  Widget _orders(List<OrderModel> orders, String emptyLabel,
      {RiderProvider? history}) {
    final dates = _dates;
    final filtered = orders.where((order) {
      final day = DateUtils.dateOnly(order.createdAt.toLocal());
      if (dates != null &&
          (day.isBefore(dates.start) || day.isAfter(dates.end))) return false;
      return order.orderNumber.toLowerCase().contains(_search) ||
          order.restaurantName.toLowerCase().contains(_search) ||
          order.customerName.toLowerCase().contains(_search);
    }).toList();
    final rowCount = filtered.isEmpty ? 1 : filtered.length;
    final canLoadMore = history?.hasOlderDeliveries == true;
    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppInsets.scrollPadding(context),
        itemCount: rowCount + (canLoadMore ? 1 : 0),
        itemBuilder: (_, index) {
          if (canLoadMore && index == rowCount) {
            return Column(
              children: [
                if (history!.historyError case final message?)
                  Text(context.tr(message)),
                AppButton(
                  label: context.tr('Load older orders'),
                  onPressed: history.loadingHistory
                      ? null
                      : history.loadOlderDeliveries,
                ),
                if (history.loadingHistory) const LinearProgressIndicator(),
              ],
            );
          }
          return filtered.isEmpty
            ? EmptyStateView(
                icon: Icons.delivery_dining,
                title: context.tr(_search.isEmpty && dates == null
                    ? emptyLabel
                    : 'No matching orders'),
                description:
                    context.tr('Orders will appear here when available.'),
              )
            : _orderSummary(filtered[index]);
        },
      ),
    );
  }

  Widget _orderSummary(OrderModel order) => AppCard(
        highlighted: _isOffer(order),
        child: ListTile(
          title: Text(order.orderNumber),
          subtitle: Text(order.restaurantName),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showDelivery(order),
        ),
      );

  void _showDelivery(OrderModel initialOrder) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) {
      return RiderDeliveryPage(
        orderId: initialOrder.id,
        advance: _advance,
        decline: _decline,
        fail: _fail,
        open: _open,
      );
    }));
  }

  Widget _earnings(RiderProvider riders) {
    if (riders.earningsLoading) {
      return const Padding(
        padding: DesignSystem.screenPadding,
        child: ShimmerLoader(height: 96),
      );
    }
    if (riders.earningsUnavailable) {
      return ListTile(
        title: Text(context.tr('Unable to load earnings. Please try again.')),
        trailing: AppButton(
          label: context.tr('Retry'),
          style: AppButtonStyle.ghost,
          onPressed: _riderId == null
              ? null
              : () => riders.watchRiderDeliveries(_riderId!),
        ),
      );
    }
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final start = switch (_earningsPeriod) {
      1 => DateTime(today.year, today.month, today.day - today.weekday + 1),
      2 => DateTime(today.year, today.month),
      _ => today,
    };
    final cashOrders = riders.earningsOrders
        .where((order) =>
            order.codSettlementStatus != null &&
            !(order.deliveredAt ?? order.updatedAt).toLocal().isBefore(start))
        .toList();
    final collected =
        cashOrders.fold<double>(0, (sum, order) => sum + order.total);
    final pending = cashOrders
        .where((order) => order.codSettlementStatus == 'pending')
        .fold<double>(0, (sum, order) => sum + order.total);
    return ListView(
      padding: AppInsets.scrollPadding(context),
      children: [
        FilterChips<int>(
          labels: {
            0: context.tr('Today'),
            1: context.tr('This week'),
            2: context.tr('This month')
          },
          selected: {_earningsPeriod},
          onChanged: (period, _) => setState(() => _earningsPeriod = period),
        ),
        AppCard(
            child: Column(children: [
          ListTile(
              title: Text(context.tr('Cash collected')),
              trailing: Text('${context.tr('Rs.')} ${collected.toStringAsFixed(2)}')),
          ListTile(
              title: Text(context.tr('To deposit')),
              trailing: Text('${context.tr('Rs.')} ${pending.toStringAsFixed(2)}')),
        ])),
        for (final order in cashOrders)
          ListTile(
            title: Text(order.orderNumber),
            subtitle: Text(context.tr(order.codSettlementStatus == 'settled'
                ? 'Settled'
                : 'To deposit')),
            trailing: Text('${context.tr('Rs.')} ${order.total.toStringAsFixed(2)}'),
          ),
        ListTile(
            title: Text(context.tr('Rider payouts are not available yet.'))),
      ],
    );
  }

  Widget _profile(RiderProvider riders) {
    final rider = riders.currentRider;
    return ListView(
      padding: AppInsets.scrollPadding(context),
      children: [
        if (rider != null) ...[
          ListTile(title: Text(rider.name),
              subtitle: Text(rider.phone, textDirection: TextDirection.ltr)),
          ListTile(
              title: Text(context.tr('Vehicle')),
              subtitle: Text(
                [rider.vehicleType, rider.vehicleNumber]
                    .whereType<String>()
                    .join(' · '),
              )),
          ListTile(
              title: Text(context.tr('Rating')),
              trailing: Text(rider.rating.toStringAsFixed(1))),
        ],
        ListTile(
          title: Text(context.tr('Settings')),
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
        AppButton(
          label: context.tr('Sign Out'),
          onPressed: () => context.read<AuthProvider>().signOut(),
        ),
      ],
    );
  }
}
