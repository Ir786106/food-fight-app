import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/rider_provider.dart';
import '../../services/rider_location_service.dart';
import '../../services/rider_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/responsive_layout.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  bool _isBroadcasting = false;
  Timer? _gpsTimer;
  double _riderLat = 31.5204;
  double _riderLng = 74.3587;
  String? _activeOrderId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      if (user != null) {
        if (auth.isAdmin || auth.isSuperAdmin) {
          context.read<OrderProvider>().watchAdminOrders();
          context.read<RiderProvider>().watchAllRiders();
        }
        context.read<RiderProvider>().watchRiderDeliveries(
              user.id,
              riderPhone: user.phone,
            );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stopGpsBroadcast();
    super.dispose();
  }

  void _startGpsBroadcast(String orderId, String riderId) {
    _stopGpsBroadcast();
    _activeOrderId = orderId;
    setState(() => _isBroadcasting = true);

    // Initial ping
    RiderLocationService.updateOrderRiderLocation(
      orderId: orderId,
      riderId: riderId,
      latitude: _riderLat,
      longitude: _riderLng,
      speed: 25.0,
      heading: 45.0,
    );

    // Periodic simulation or actual sensor broadcast
    _gpsTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
      if (!mounted) return;
      // Slight coordinate jitter to simulate live motion on customer map
      _riderLat += 0.00015;
      _riderLng += 0.00012;
      await RiderLocationService.updateOrderRiderLocation(
        orderId: orderId,
        riderId: riderId,
        latitude: _riderLat,
        longitude: _riderLng,
        speed: 28.5,
        heading: 50.0,
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

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: cleanPhone));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phone number $cleanPhone copied to clipboard.'),
              backgroundColor: AppColors.brandMaroon,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: cleanPhone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone number $cleanPhone copied to clipboard.'),
            backgroundColor: AppColors.brandMaroon,
          ),
        );
      }
    }
  }

  Future<void> _openMapNavigation(String address) async {
    final query = Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: address));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery address copied to clipboard.'),
              backgroundColor: AppColors.brandMaroon,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: address));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery address copied to clipboard.'),
            backgroundColor: AppColors.brandMaroon,
          ),
        );
      }
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
            content: Text('Delivery route started! Live GPS tracking is broadcasting to customer. 🛵'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleCompleteDelivery(OrderModel order) async {
    final isCod = order.paymentMethod.toLowerCase().contains('cash') ||
        order.paymentMethod.toLowerCase().contains('cod');

    final orderProv = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Text('Confirm Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deliver order ${order.orderNumber} to:'),
            const SizedBox(height: 6),
            Text(
              order.customerName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            if (isCod)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_rounded, color: AppColors.brandMaroon, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cash to Collect (COD):', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          Text(
                            'Rs. ${order.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandMaroon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text('Paid Online • No cash collection needed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Delivered'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _stopGpsBroadcast();
    final ok = await orderProv.updateOrderStatus(
          order.id,
          OrderStatus.delivered,
        );

    if (ok && mounted) {
      messenger.showSnackBar(
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
    final riderProvider = context.watch<RiderProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Filter active deliveries
    final List<OrderModel> activeDeliveries = (auth.isAdmin || auth.isSuperAdmin)
        ? orderProvider.adminOrders.where((o) {
            return (o.status == OrderStatus.assigned ||
                    o.status == OrderStatus.pickedUp ||
                    o.status == OrderStatus.outForDelivery ||
                    o.riderId == user?.id) &&
                o.status != OrderStatus.delivered &&
                o.status != OrderStatus.cancelled;
          }).toList()
        : riderProvider.assignedDeliveries;

    // Filter completed deliveries
    final List<OrderModel> completedDeliveries = (auth.isAdmin || auth.isSuperAdmin)
        ? orderProvider.adminOrders.where((o) => o.status == OrderStatus.delivered).toList()
        : riderProvider.completedDeliveries;

    // COD calculation
    final codPending = activeDeliveries.where((o) {
      final m = o.paymentMethod.toLowerCase();
      return m.contains('cash') || m.contains('cod');
    }).fold<double>(0.0, (sum, o) => sum + o.total);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (auth.isSuperAdmin) {
          Navigator.of(context).pushNamedAndRemoveUntil('/super-admin/dashboard', (r) => false);
        } else if (auth.isAdmin) {
          Navigator.of(context).pushNamedAndRemoveUntil('/admin/dashboard', (r) => false);
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.brandMaroon,
          foregroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandYellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.two_wheeler_rounded, color: AppColors.brandMaroon, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rider Dispatch Console',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    'Food Fight Delivery Operations',
                    style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (auth.isAdmin || auth.isSuperAdmin)
              IconButton(
                icon: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.brandYellow),
                tooltip: auth.isSuperAdmin ? 'Super Admin HQ' : 'Restaurant Admin Portal',
                onPressed: () {
                  if (auth.isSuperAdmin) {
                    Navigator.of(context).pushNamed('/super-admin/dashboard');
                  } else {
                    Navigator.of(context).pushNamed('/admin/dashboard');
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.storefront_rounded),
              tooltip: 'Customer Storefront',
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
            ),
          ],
        ),
        body: ResponsiveContainer.content(
          maxWidth: 880,
          child: Column(
            children: [
              // Admin Switch Banner (when Admin / Super Admin is viewing Rider Console)
              if (auth.isAdmin || auth.isSuperAdmin)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow.withValues(alpha: isDark ? 0.2 : 0.25),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.brandYellow.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, size: 16, color: AppColors.brandMaroon),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.isSuperAdmin
                              ? 'Logged in as Super Admin • Viewing Rider Console'
                              : 'Logged in as Restaurant Admin • Viewing Rider Console',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          if (auth.isSuperAdmin) {
                            Navigator.of(context).pushReplacementNamed('/super-admin/dashboard');
                          } else {
                            Navigator.of(context).pushReplacementNamed('/admin/dashboard');
                          }
                        },
                        child: Text(
                          'Exit to Admin',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Rider Status & GPS Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isOnline
                              ? const [Color(0xFF2E090B), Color(0xFF190406)]
                              : const [Color(0xFF262626), Color(0xFF151515)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _isOnline
                              ? AppColors.brandYellow.withValues(alpha: 0.4)
                              : Colors.white12,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Stack(
                                children: [
                                  const CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppColors.brandYellow,
                                    child: Icon(
                                      Icons.two_wheeler_rounded,
                                      color: AppColors.brandMaroon,
                                      size: 30,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: _isOnline ? AppColors.success : Colors.grey,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
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
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _isOnline
                                                ? (_isBroadcasting ? Colors.redAccent : AppColors.success)
                                                : Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _isOnline
                                                ? (_isBroadcasting
                                                    ? 'LIVE GPS BROADCASTING'
                                                    : 'ONLINE • READY FOR DELIVERIES')
                                                : 'OFFLINE • SHIFT PAUSED',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: _isOnline
                                                  ? (_isBroadcasting ? Colors.redAccent : AppColors.brandYellow)
                                                  : Colors.white60,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isOnline,
                                activeThumbColor: AppColors.brandYellow,
                                activeTrackColor: AppColors.brandMaroon,
                                onChanged: (val) async {
                                  setState(() => _isOnline = val);
                                  if (!val) _stopGpsBroadcast();
                                  if (user != null) {
                                    try {
                                      await RiderService.setRiderOnline(user.id, val);
                                    } catch (_) {}
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 14),

                          // Quick Shift Stats Row
                          Row(
                            children: [
                              _buildHeaderStat(
                                label: 'Active Tasks',
                                value: activeDeliveries.length.toString(),
                                icon: Icons.pending_actions_rounded,
                                color: AppColors.brandYellow,
                              ),
                              Container(width: 1, height: 32, color: Colors.white12),
                              _buildHeaderStat(
                                label: 'Delivered Today',
                                value: completedDeliveries.length.toString(),
                                icon: Icons.task_alt_rounded,
                                color: AppColors.success,
                              ),
                              Container(width: 1, height: 32, color: Colors.white12),
                              _buildHeaderStat(
                                label: 'COD Cash Pool',
                                value: 'Rs. ${codPending.toStringAsFixed(0)}',
                                icon: Icons.payments_outlined,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tab Selector: Active vs Completed
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                        unselectedLabelColor: colorScheme.onSurfaceVariant,
                        indicatorColor: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(
                            icon: const Icon(Icons.two_wheeler_rounded, size: 18),
                            text: 'Active Tasks (${activeDeliveries.length})',
                          ),
                          Tab(
                            icon: const Icon(Icons.history_rounded, size: 18),
                            text: 'Completed Today (${completedDeliveries.length})',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tab Views
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        if (_tabController.index == 0) {
                          return _buildActiveDeliveriesTab(
                            context: context,
                            orders: activeDeliveries,
                            isDark: isDark,
                            colorScheme: colorScheme,
                          );
                        } else {
                          return _buildCompletedDeliveriesTab(
                            context: context,
                            orders: completedDeliveries,
                            isDark: isDark,
                            colorScheme: colorScheme,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveriesTab({
    required BuildContext context,
    required List<OrderModel> orders,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: const EmptyStateView(
          icon: Icons.done_all_rounded,
          title: 'All Clear Champion! 🛵',
          description: 'No pending orders waiting for delivery right now. Stay online to catch new orders.',
        ),
      );
    }

    return Column(
      children: orders.map((order) {
        final isEnRoute = order.status == OrderStatus.outForDelivery;
        final isCod = order.paymentMethod.toLowerCase().contains('cash') ||
            order.paymentMethod.toLowerCase().contains('cod');

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEnRoute
                  ? AppColors.success
                  : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
              width: isEnRoute ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Order ID + Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkYellowSoft : AppColors.yellowSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.orderNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCod)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brandYellow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'COD',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandMaroon,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PAID ONLINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEnRoute
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.brandYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isEnRoute) ...[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            isEnRoute ? 'ON THE WAY' : order.statusLabel.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: isEnRoute ? AppColors.success : (isDark ? AppColors.brandYellow : AppColors.brandMaroon),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Customer Info Row + Call Button
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.person_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            order.customerPhone.isNotEmpty ? order.customerPhone : 'No phone linked',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (order.customerPhone.isNotEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () => _makePhoneCall(order.customerPhone),
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Delivery Destination Address + Navigation Button
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface, height: 1.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _openMapNavigation(order.deliveryAddress),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.directions_rounded, size: 14, color: AppColors.brandMaroon),
                              SizedBox(width: 4),
                              Text('Map', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Items summary
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: Text(
                      '${order.items.length} items ordered • Rs. ${order.total.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    children: order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.displayName, style: const TextStyle(fontSize: 12))),
                            Text('Rs. ${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const Divider(height: 16),

                // Bottom Action Bar: Payment Pill + Delivery Workflow Buttons
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCod ? 'Cash to Collect:' : 'Total Amount:',
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          'Rs. ${order.total.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isCod ? AppColors.brandMaroon : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!isEnRoute)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandYellow,
                          foregroundColor: AppColors.brandMaroon,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _handleStartDelivery(order),
                        icon: const Icon(Icons.two_wheeler_rounded, size: 18),
                        label: const Text(
                          'Start Route',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                      )
                    else
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _handleCompleteDelivery(order),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text(
                          'Mark Delivered',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompletedDeliveriesTab({
    required BuildContext context,
    required List<OrderModel> orders,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: const EmptyStateView(
          icon: Icons.history_rounded,
          title: 'No Completed Orders Yet',
          description: 'Deliveries you complete today will appear in this history list.',
        ),
      );
    }

    return Column(
      children: orders.map((order) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.orderNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Rs. ${order.total.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.customerName} • ${order.deliveryAddress}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
