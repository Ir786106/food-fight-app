import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/rider_provider.dart';
import '../../services/rider_location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/responsive_layout.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  bool _isOnline = true;
  bool _isBroadcasting = false;
  Timer? _gpsTimer;
  double _mockLat = 31.5204;
  double _mockLng = 74.3587;
  String? _activeOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      if (user != null) {
        if (auth.isAdmin) {
          context.read<OrderProvider>().watchAdminOrders();
        } else {
          context.read<RiderProvider>().watchRiderDeliveries(user.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _stopGpsBroadcast();
    super.dispose();
  }

  void _startGpsBroadcast(String orderId, String riderId) {
    _stopGpsBroadcast();
    _activeOrderId = orderId;
    setState(() => _isBroadcasting = true);

    // Periodically update GPS coordinates for the active order
    _gpsTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted) return;
      // Simulate real movement heading towards destination
      _mockLat += 0.0003;
      _mockLng += 0.0002;

      await RiderLocationService.updateOrderRiderLocation(
        orderId: orderId,
        riderId: riderId,
        latitude: _mockLat,
        longitude: _mockLng,
        speed: 28.5,
        heading: 45.0,
      );
    });
  }

  void _stopGpsBroadcast() {
    _gpsTimer?.cancel();
    _gpsTimer = null;
    final riderId = context.read<AuthProvider>().currentUser?.id ?? 'rider_1';
    if (_activeOrderId != null) {
      RiderLocationService.stopBroadcasting(
        orderId: _activeOrderId!,
        riderId: riderId,
      );
      _activeOrderId = null;
    }
    if (mounted) {
      setState(() => _isBroadcasting = false);
    }
  }

  Future<void> _handleStartDelivery(OrderModel order) async {
    final riderId = context.read<AuthProvider>().currentUser?.id ?? 'rider_1';
    final ok = await context.read<OrderProvider>().updateOrderStatus(
          order.id,
          OrderStatus.outForDelivery,
        );

    if (ok) {
      _startGpsBroadcast(order.id, riderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery started! Live GPS tracking is broadcasting to customer. 🛵'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleCompleteDelivery(OrderModel order) async {
    _stopGpsBroadcast();
    final ok = await context.read<OrderProvider>().updateOrderStatus(
          order.id,
          OrderStatus.delivered,
        );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order delivered successfully! Great job champion! 🏆'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final orderProvider = context.watch<OrderProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final riderProvider = context.watch<RiderProvider>();

    // Filter orders assigned to this rider or available for dispatch
    final myDeliveries = auth.isAdmin
        ? orderProvider.adminOrders.where((o) {
            return (o.riderId == user?.id || o.riderId == null || o.status == OrderStatus.assigned || o.status == OrderStatus.outForDelivery) &&
                o.status != OrderStatus.delivered &&
                o.status != OrderStatus.cancelled;
          }).toList()
        : riderProvider.assignedDeliveries.where((o) {
            return o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled;
          }).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.two_wheeler_rounded, color: AppColors.primaryYellow),
              SizedBox(width: 8),
              Text(
                'Rider Delivery Console',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface,
          foregroundColor: colorScheme.onSurface,
          actions: [
            IconButton(
              icon: const Icon(Icons.storefront_rounded),
              tooltip: 'Customer Storefront',
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
            ),
          ],
        ),
        body: ResponsiveContainer.content(
          maxWidth: 760,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Rider Status & GPS Toggle Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isOnline
                        ? const [AppColors.darkBrown, Color(0xFF230F0A)]
                        : const [Color(0xFF2E2018), Color(0xFF170F0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            _isOnline ? Icons.two_wheeler_rounded : Icons.power_settings_new_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Delivery Champion',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _isOnline
                                    ? (_isBroadcasting
                                        ? '🔴 LIVE GPS BROADCASTING TO ORDER'
                                        : '🟡 ONLINE • Ready for Deliveries')
                                    : '⚪ OFFLINE',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isOnline,
                          activeThumbColor: AppColors.darkBrown,
                          activeTrackColor: AppColors.primaryYellow,
                          onChanged: (val) {
                            setState(() => _isOnline = val);
                            if (!val) _stopGpsBroadcast();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assigned Deliveries (${myDeliveries.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final currentAuth = context.read<AuthProvider>();
                      final currentUser = currentAuth.currentUser;
                      if (currentAuth.isAdmin) {
                        context.read<OrderProvider>().watchAdminOrders();
                      } else if (currentUser != null) {
                        context.read<RiderProvider>().watchRiderDeliveries(currentUser.id);
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (myDeliveries.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: const EmptyStateView(
                    icon: Icons.done_all_rounded,
                    title: 'No Pending Deliveries',
                    description: 'You are all caught up! New orders assigned to you will show up here.',
                  ),
                )
              else
                ...myDeliveries.map((order) {
                  final isEnRoute = order.status == OrderStatus.outForDelivery;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isEnRoute ? AppColors.success : colorScheme.outlineVariant,
                        width: isEnRoute ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                order.orderNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isEnRoute ? AppColors.success.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isEnRoute ? 'ON THE WAY' : order.statusLabel.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.5,
                                    color: isEnRoute ? AppColors.success : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                '${order.customerName} • ${order.customerPhone}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.error),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  order.deliveryAddress,
                                  style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Text(
                                'Rs. ${order.total.toStringAsFixed(0)} • ${order.paymentMethod}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                              const Spacer(),
                              if (!isEnRoute)
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primaryYellow,
                                    foregroundColor: AppColors.darkBrown,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _handleStartDelivery(order),
                                  icon: const Icon(Icons.delivery_dining_rounded, size: 18),
                                  label: const Text('Start Delivery'),
                                )
                              else
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _handleCompleteDelivery(order),
                                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                                  label: const Text('Complete Delivery'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
