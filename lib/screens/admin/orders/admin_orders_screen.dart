import 'package:food_fight/core/design_system/components.dart' show AppDataTable;
import 'package:food_fight/core/utils/admin_csv_export.dart';
import 'package:food_fight/core/utils/app_snackbar.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/providers/order_provider.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/widgets/admin/admin_scaffold.dart';
import 'package:food_fight/widgets/admin/status_badge.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/empty_state_view.dart';
import 'package:food_fight/widgets/common/error_view.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'order_detail_modal.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String? _lastBranchId;
  bool _initialized = false;
  String _dateFilter = 'all'; // 'all', 'today', 'yesterday', 'week'

  static const List<Map<String, String>> _tabs = [
    {'title': 'All', 'status': 'all'},
    {'title': 'Pending', 'status': 'pending'},
    {'title': 'Accepted', 'status': 'accepted'},
    {'title': 'Preparing', 'status': 'preparing'},
    {'title': 'Ready', 'status': 'ready'},
    {'title': 'Assigned', 'status': 'assigned'},
    {'title': 'Picked Up', 'status': 'pickedUp'},
    {'title': 'Out for Delivery', 'status': 'outForDelivery'},
    {'title': 'Delivered', 'status': 'delivered'},
    {'title': 'Cancelled', 'status': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final branchId = auth.isSuperAdmin ? null : auth.currentUser?.branchId?.trim();
    if (!auth.isSuperAdmin && (branchId == null || branchId.isEmpty || branchId.toLowerCase() == 'all')) return;
    if (!_initialized || _lastBranchId != branchId) {
      _initialized = true;
      _lastBranchId = branchId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lastBranchId == branchId) {
          context.read<OrderProvider>().watchAdminOrders(branchId: branchId);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    final auth = context.watch<AuthProvider>();
    final branch = auth.currentUser?.branchId?.trim();
    final hasScope = auth.isSuperAdmin ||
        (branch != null && branch.isNotEmpty && branch.toLowerCase() != 'all');
    if (!hasScope) {
      return const AdminScaffold(
        currentRoute: '/admin/orders',
        body: ErrorView(message: 'This account needs a branch assignment before viewing orders.'),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        }
      },
      child: AdminScaffold(
        currentRoute: '/admin/orders',
        backgroundColor: AdminTheme.getBackground(context),
        appBar: AppBar(
          title: const Text(
            'Order Management',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: AdminTheme.primaryBlue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh Orders',
              onPressed: orderProvider.refreshAdminOrders,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(108),
            child: Column(
              children: [
                // Search and Date Filter Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Search order #, customer, address...',
                              hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _dateFilter,
                            icon: const Icon(Icons.calendar_today_rounded, size: 15, color: AdminTheme.primaryBlue),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.primaryBlue),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Dates')),
                              DropdownMenuItem(value: 'today', child: Text('Today')),
                              DropdownMenuItem(value: 'yesterday', child: Text('Yesterday')),
                              DropdownMenuItem(value: 'week', child: Text('This Week')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _dateFilter = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: _tabs.map((t) {
                    final statusKey = t['status']!;
                    int count = 0;
                    switch (statusKey) {
                      case 'all':
                        count = orderProvider.allCount;
                        break;
                      case 'pending':
                        count = orderProvider.pendingCount;
                        break;
                      case 'preparing':
                        count = orderProvider.preparingCount;
                        break;
                      case 'ready':
                        count = orderProvider.readyCount;
                        break;
                      case 'outForDelivery':
                        count = orderProvider.outForDeliveryCount;
                        break;
                      case 'delivered':
                        count = orderProvider.deliveredCount;
                        break;
                      case 'cancelled':
                        count = orderProvider.cancelledCount;
                        break;
                      default:
                        count = orderProvider.adminOrders
                            .where((o) => o.status.name.toLowerCase() == statusKey.toLowerCase())
                            .length;
                        break;
                    }

                    return Tab(
                      child: Row(
                        children: [
                          Text(t['title']!),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        body: !orderProvider.isWatchingAdminScope(auth.isSuperAdmin ? null : branch)
            ? const LoadingIndicator(message: 'Loading orders...')
            : TabBarView(
          controller: _tabController,
          children: _tabs.map((t) => _OrdersTabList(
            status: t['status']!,
            searchQuery: _searchCtrl.text.trim().toLowerCase(),
            dateFilter: _dateFilter,
            onClearFilter: () {
              _searchCtrl.clear();
              setState(() => _dateFilter = 'all');
            },
          )).toList(),
        ),
      ),
    );
  }
}

class _OrdersTabList extends StatelessWidget {
  final String status;
  final String searchQuery;
  final String dateFilter;
  final VoidCallback onClearFilter;

  const _OrdersTabList({
    required this.status,
    required this.searchQuery,
    required this.dateFilter,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    if (orderProvider.isLoading && orderProvider.adminOrders.isEmpty) {
      return const LoadingIndicator(message: 'Loading orders...');
    }

    if (orderProvider.errorMessage != null && orderProvider.adminOrders.isEmpty) {
      return ErrorView(
        message: orderProvider.errorMessage!,
        onRetry: () => context.read<OrderProvider>().refreshAdminOrders(),
      );
    }

    final allOrders = orderProvider.adminOrders;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final orders = allOrders.where((o) {
      // 1. Status filter
      if (status != 'all') {
        final orderStatus = o.status.name.toLowerCase();
        final targetStatus = status.toLowerCase();
        if (orderStatus != targetStatus) return false;
      }

      // 2. Search query filter
      if (searchQuery.isNotEmpty) {
        final matchesOrderNum = o.orderNumber.toLowerCase().contains(searchQuery);
        final matchesCustomer = o.customerName.toLowerCase().contains(searchQuery);
        final matchesAddress = o.deliveryAddress.toLowerCase().contains(searchQuery);
        final matchesPhone = o.customerPhone.toLowerCase().contains(searchQuery);
        if (!matchesOrderNum && !matchesCustomer && !matchesAddress && !matchesPhone) {
          return false;
        }
      }

      // 3. Date filter
      if (dateFilter == 'today') {
        if (o.createdAt.isBefore(startOfToday)) return false;
      } else if (dateFilter == 'yesterday') {
        if (o.createdAt.isBefore(startOfYesterday) || !o.createdAt.isBefore(startOfToday)) return false;
      } else if (dateFilter == 'week') {
        if (o.createdAt.isBefore(sevenDaysAgo)) return false;
      }

      return true;
    }).toList();

    final content = _buildResults(context, orders);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${orders.length} matches · ${allOrders.length} orders loaded'),
              TextButton.icon(
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export shown orders'),
                onPressed: orders.isEmpty ? null : () => _export(context, orders),
              ),
              if (orderProvider.canLoadMoreAdminOrders)
                TextButton(
                  onPressed: orderProvider.loadMoreAdminOrders,
                  child: const Text('Load older orders'),
                ),
            ],
          ),
        ),
        if (orderProvider.isLoading || orderProvider.isPagingAdminOrders)
          const LinearProgressIndicator(),
        if (orderProvider.adminPageError case final error?)
          Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildResults(BuildContext context, List<OrderModel> orders) {
    if (orders.isEmpty) {
      final isFiltered = searchQuery.isNotEmpty || dateFilter != 'all';
      return EmptyStateView(
        icon: Icons.receipt_long_rounded,
        title: isFiltered ? 'No Orders Match Filter' : 'No Orders In This Tab',
        description: isFiltered
            ? 'No orders found matching "$searchQuery" or the selected date range.'
            : (status == 'all'
                ? 'Incoming customer orders will appear here in real-time.'
                : 'No orders currently matching "$status" status.'),
        buttonText: isFiltered ? 'Clear Filters' : 'Refresh Orders',
        onButtonPressed: isFiltered
            ? onClearFilter
            : () => context.read<OrderProvider>().refreshAdminOrders(),
      );
    }

    if (MediaQuery.sizeOf(context).width > 1024) return _desktopTable(context, orders);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AdminTheme.getCardBg(context);
    final textDark = AdminTheme.getTextDark(context);
    final textMuted = AdminTheme.getTextMuted(context);

    return ResponsiveContainer.content(
      maxWidth: 1200,
      child: RefreshIndicator(
        onRefresh: () async => context.read<OrderProvider>().refreshAdminOrders(),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];

            return Material(
              color: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openOrder(context, order),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Order Number + Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AdminTheme.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt_rounded, color: AdminTheme.primaryBlue, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                order.orderNumber,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                          StatusBadge(status: order.status.name),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Customer Info & Address
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.customerName.isNotEmpty ? order.customerName : 'Customer',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatDate(order.createdAt),
                            style: TextStyle(color: textMuted, fontSize: 11.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.deliveryAddress,
                              style: TextStyle(color: textMuted, fontSize: 12.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      // Items summary and Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${order.items.length} ${order.items.length == 1 ? "item" : "items"} • ${order.paymentMethod.toUpperCase()}',
                            style: TextStyle(color: textMuted, fontSize: 12.5, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Rs. ${order.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AdminTheme.primaryBlue,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openOrder(BuildContext context, OrderModel order) {
    if (MediaQuery.sizeOf(context).width <= 1024) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => OrderDetailModal(order: order),
      );
      return;
    }
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, _, __) => SafeArea(
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 560,
            child: Material(
              color: Colors.transparent,
              child: OrderDetailModal(order: order),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, List<OrderModel> orders) async {
    try {
      await shareAdminCsv(
        context,
        filename: 'food-fight-orders.csv',
        rows: [
          ['Order', 'Branch', 'Status', 'Placed at (UTC)', 'Payment', 'Total (PKR)'],
          for (final order in orders)
            [order.orderNumber, order.branchId ?? '', order.status.name,
              order.createdAt.toUtc().toIso8601String(), order.paymentMethod, order.total],
        ],
      );
    } catch (_) {
      if (context.mounted) AppSnackbar.showError(context, 'Could not export orders.');
    }
  }

  Widget _desktopTable(BuildContext context, List<OrderModel> orders) {
    final localizations = MaterialLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppDataTable(
        columns: const [
          DataColumn(label: Text('Order')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Total'), numeric: true),
          DataColumn(label: Text('Details')),
        ],
        rows: [
          for (final order in orders)
            DataRow(cells: [
              DataCell(Text(order.orderNumber)),
              DataCell(Text(order.customerName)),
              DataCell(StatusBadge(status: order.status.name)),
              DataCell(Text(localizations.formatCompactDate(order.createdAt.toLocal()))),
              DataCell(Text('Rs. ${order.total.toStringAsFixed(0)}')),
              DataCell(IconButton(
                tooltip: 'Open ${order.orderNumber}',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _openOrder(context, order),
              )),
            ]),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}
