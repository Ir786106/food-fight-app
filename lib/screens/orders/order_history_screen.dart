import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin/status_badge.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/responsive_layout.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<OrderProvider>().watchCustomerOrders(auth.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final customerId = auth.currentUser?.id ?? '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('My Orders 🥊')),
      body: SafeArea(
        child: ResponsiveContainer.content(
          maxWidth: 860,
          child: customerId.isEmpty
              ? EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  title: 'Please Log In',
                  description: 'Log in to your account to view your past orders and active deliveries.',
                  buttonText: 'Log In Now',
                  onButtonPressed: () => Navigator.of(context).pushNamed('/login'),
                )
              : Builder(
                  builder: (context) {
                    if (orderProvider.isLoading && orderProvider.customerOrders.isEmpty) {
                      return const LoadingIndicator(message: 'Loading your orders...');
                    }

                    if (orderProvider.errorMessage != null && orderProvider.customerOrders.isEmpty) {
                      return ErrorView(
                        message: orderProvider.errorMessage!,
                        onRetry: () => orderProvider.watchCustomerOrders(customerId),
                      );
                    }

                    final orders = orderProvider.customerOrders;

                    if (orders.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Orders Yet',
                        description: 'Your placed orders will show up here in real time.',
                        buttonText: 'Order Food Now',
                        onButtonPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => orderProvider.watchCustomerOrders(customerId),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = orders[index];

                          return Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colorScheme.outlineVariant),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.of(context).pushNamed(
                                  '/order-tracking',
                                  arguments: order,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              order.orderNumber,
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
                                          StatusBadge(status: order.status.name),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '${order.items.length} items • ${order.paymentMethod}',
                                        style: TextStyle(
                                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total: Rs. ${order.total.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                'Track Order',
                                                style: TextStyle(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colorScheme.primary),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
