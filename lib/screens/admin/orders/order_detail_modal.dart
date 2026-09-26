import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/providers/order_provider.dart';
import 'package:food_fight/providers/rider_provider.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/widgets/admin/status_badge.dart';

/// Modal bottom sheet displaying complete order details and status actions
class OrderDetailModal extends StatefulWidget {
  final OrderModel order;

  const OrderDetailModal({super.key, required this.order});

  @override
  State<OrderDetailModal> createState() => _OrderDetailModalState();
}

class _OrderDetailModalState extends State<OrderDetailModal> {
  bool _isUpdating = false;

  OrderStatus? _getNextStatus(OrderStatus current) {
    switch (current) {
      case OrderStatus.pending:
        return OrderStatus.accepted;
      case OrderStatus.accepted:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.outForDelivery;
      case OrderStatus.outForDelivery:
        return OrderStatus.delivered;
      default:
        return null;
    }
  }

  String _getNextStatusActionName(OrderStatus next) {
    switch (next) {
      case OrderStatus.accepted:
        return 'Accept Order';
      case OrderStatus.preparing:
        return 'Start Preparing';
      case OrderStatus.ready:
        return 'Mark Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Send Out for Delivery';
      case OrderStatus.delivered:
        return 'Mark Delivered';
      default:
        return 'Advance Status';
    }
  }

  Future<void> _advanceStatus(OrderStatus nextStatus) async {
    setState(() => _isUpdating = true);
    try {
      final success = await context.read<OrderProvider>().updateOrderStatus(widget.order.id, nextStatus);
      if (mounted) {
        Navigator.pop(context);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order status updated to ${nextStatus.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.getCardBg(context),
        title: Text(
          'Cancel Order',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AdminTheme.getTextDark(context),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please specify a reason for cancelling this order:',
              style: TextStyle(fontSize: 13, color: AdminTheme.getTextMuted(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              maxLines: 2,
              style: TextStyle(color: AdminTheme.getTextDark(context)),
              decoration: InputDecoration(
                hintText: 'e.g., Item out of stock, Customer requested',
                hintStyle: TextStyle(color: AdminTheme.getTextMuted(context)),
                filled: true,
                fillColor: isDark ? const Color(0xFF22222E) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Dismiss',
              style: TextStyle(color: AdminTheme.getTextMuted(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isUpdating = true);
              await context.read<OrderProvider>().updateOrderStatus(
                widget.order.id,
                OrderStatus.cancelled,
                cancellationReason: reason,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAssignRiderSheet() {
    final riderProvider = context.read<RiderProvider>();
    riderProvider.watchAllRiders();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AdminTheme.getCardBg(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assign Delivery Rider',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.getTextDark(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Consumer<RiderProvider>(
                  builder: (context, provider, _) {
                    final riders = provider.activeRiders;
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (riders.isEmpty) {
                      return Center(
                        child: Text(
                          'No active delivery riders found.\nAdd riders in Fleet Management.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AdminTheme.getTextMuted(context)),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: riders.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (context, index) {
                        final rider = riders[index];
                        final isAssigned = widget.order.riderId == rider.id;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: rider.isOnline ? Colors.green.shade100 : Colors.grey.shade200,
                            child: Icon(
                              Icons.delivery_dining_rounded,
                              color: rider.isOnline ? Colors.green.shade800 : Colors.grey.shade600,
                            ),
                          ),
                          title: Text(
                            rider.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AdminTheme.getTextDark(context),
                            ),
                          ),
                          subtitle: Text(
                            '${rider.phone} • ${(rider.vehicleType?.toUpperCase() ?? "BIKE")} • ${rider.isOnline ? "Online" : "Offline"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AdminTheme.getTextMuted(context),
                            ),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAssigned ? Colors.grey : AdminTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: isAssigned
                                ? null
                                : () async {
                                    Navigator.pop(ctx);
                                    setState(() => _isUpdating = true);
                                    final success = await provider.assignRider(
                                      orderId: widget.order.id,
                                      riderId: rider.id,
                                      riderName: rider.name,
                                      riderPhone: rider.phone,
                                    );
                                    if (mounted) {
                                      setState(() => _isUpdating = false);
                                      if (success) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Assigned order to ${rider.name}'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: Text(isAssigned ? 'Assigned' : 'Assign'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final nextStatus = _getNextStatus(order.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AdminTheme.getCardBg(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AdminTheme.getTextDark(context),
                          ),
                        ),
                        Text(
                          '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} at ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AdminTheme.getTextMuted(context), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: order.status.name),
                ],
              ),
              const Divider(height: 28),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Delivery & Customer Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E28) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E2E3C) : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (order.customerName.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 18, color: AdminTheme.primaryBlue),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Customer: ${order.customerName}${order.customerPhone.isNotEmpty ? ' (${order.customerPhone})' : ''}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AdminTheme.getTextDark(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 18, color: AdminTheme.primaryBlue),
                              const SizedBox(width: 6),
                              Text(
                                'Delivery Address',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AdminTheme.getTextDark(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            order.deliveryAddress.isNotEmpty
                                ? order.deliveryAddress
                                : 'No address provided',
                            style: TextStyle(fontSize: 13, color: AdminTheme.getTextMuted(context)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.payment_rounded, size: 18, color: Colors.green),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Payment: ${order.paymentMethod}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AdminTheme.getTextDark(context),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order.paymentStatus.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (order.cancellationReason != null && order.cancellationReason!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Reason for Cancellation: ${order.cancellationReason}',
                                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Delivery Rider Assignment Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E26) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.delivery_dining_rounded, size: 18, color: AdminTheme.primaryBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delivery Rider',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: AdminTheme.getTextDark(context),
                                    ),
                                  ),
                                ],
                              ),
                              if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled)
                                TextButton.icon(
                                  onPressed: _isUpdating ? null : _showAssignRiderSheet,
                                  icon: Icon(
                                    order.riderId != null ? Icons.swap_horiz_rounded : Icons.person_add_alt_1_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    order.riderId != null ? 'Change Rider' : 'Assign Rider',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AdminTheme.primaryBlue,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (order.riderName != null && order.riderName!.isNotEmpty) ...[
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AdminTheme.primaryBlue.withValues(alpha: 0.15),
                                  child: const Icon(Icons.person, size: 16, color: AdminTheme.primaryBlue),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.riderName!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AdminTheme.getTextDark(context),
                                        ),
                                      ),
                                      if (order.riderPhone != null && order.riderPhone!.isNotEmpty)
                                        Text(
                                          order.riderPhone!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AdminTheme.getTextMuted(context),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'DISPATCHED',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Text(
                              'No rider assigned to this delivery yet.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontStyle: FontStyle.italic,
                                color: AdminTheme.getTextMuted(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Order Items
                    Text(
                      'Items Ordered',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AdminTheme.getTextDark(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AdminTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${item.quantity}x',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AdminTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: AdminTheme.getTextDark(context),
                                    ),
                                  ),
                                  if (item.selectedVariant?.description != null && item.selectedVariant!.description!.isNotEmpty)
                                    Text(
                                      item.selectedVariant!.description!,
                                      style: TextStyle(color: AdminTheme.getTextMuted(context), fontSize: 11),
                                    ),
                                  if (item.addonsDescription != null)
                                    Text(
                                      item.addonsDescription!,
                                      style: const TextStyle(color: AdminTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AdminTheme.getTextDark(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const Divider(height: 24),

                    // Price Breakdown
                    _summaryRow(context, 'Subtotal', 'Rs. ${order.subtotal.toStringAsFixed(0)}'),
                    if (order.discount > 0)
                      _summaryRow(context, 'Discount', '- Rs. ${order.discount.toStringAsFixed(0)}', color: Colors.green),
                    _summaryRow(context, 'Delivery Fee', 'Rs. ${order.deliveryCharge.toStringAsFixed(0)}'),
                    const Divider(height: 16),
                    _summaryRow(context, 'Total Amount', 'Rs. ${order.total.toStringAsFixed(0)}', isBold: true),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Action Buttons
              if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isUpdating ? null : _showCancelDialog,
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    if (nextStatus != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isUpdating ? null : () => _advanceStatus(nextStatus),
                          child: _isUpdating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _getNextStatusActionName(nextStatus),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(BuildContext context, String title, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                color: isBold ? AdminTheme.getTextDark(context) : AdminTheme.getTextMuted(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 16 : 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: color ?? (isBold ? AdminTheme.primaryBlue : AdminTheme.getTextDark(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
