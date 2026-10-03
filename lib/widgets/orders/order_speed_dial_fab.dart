import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

/// Speed Dial FAB with quick actions (Ref C): Track order, Chat support, Reorder.
class OrderSpeedDialFab extends StatefulWidget {
  const OrderSpeedDialFab({super.key});

  @override
  State<OrderSpeedDialFab> createState() => _OrderSpeedDialFabState();
}

class _OrderSpeedDialFabState extends State<OrderSpeedDialFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _expandAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animCtrl.forward();
      } else {
        _animCtrl.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() => _isOpen = false);
      _animCtrl.reverse();
    }
  }

  void _trackActiveOrder() {
    _close();
    final orderProvider = context.read<OrderProvider>();
    final activeOrders = orderProvider.customerOrders.where((o) =>
        o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).toList();

    if (activeOrders.isNotEmpty) {
      final activeOrder = activeOrders.first;
      Navigator.of(context).pushNamed('/order-tracking', arguments: activeOrder);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No active delivery to track right now 🥊'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radius12)),
        ),
      );
    }
  }

  void _openChatSupport() {
    _close();
    Navigator.of(context).pushNamed('/chat');
  }

  void _reorderMenu() {
    _close();
    Navigator.of(context).pushNamed('/menu');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 74, right: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expanded Action 1: Track Order
          ScaleTransition(
            scale: _expandAnim,
            alignment: Alignment.bottomRight,
            child: _buildActionPill(
              icon: Icons.delivery_dining_rounded,
              label: 'Track Order',
              onTap: _trackActiveOrder,
              colorScheme: colorScheme,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 10),

          // Expanded Action 2: Chat Support
          ScaleTransition(
            scale: _expandAnim,
            alignment: Alignment.bottomRight,
            child: _buildActionPill(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Support Chat',
              onTap: _openChatSupport,
              colorScheme: colorScheme,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 10),

          // Expanded Action 3: Reorder / Menu
          ScaleTransition(
            scale: _expandAnim,
            alignment: Alignment.bottomRight,
            child: _buildActionPill(
              icon: Icons.restaurant_menu_rounded,
              label: 'Order Again',
              onTap: _reorderMenu,
              colorScheme: colorScheme,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 12),

          // Main FAB Trigger (Labeled Quick Action)
          GestureDetector(
            onTap: _toggle,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.brandYellow,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandYellow.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    turns: _isOpen ? 0.375 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      _isOpen ? Icons.close_rounded : Icons.headset_mic_rounded,
                      color: AppColors.brandMaroon,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isOpen ? 'Close' : 'Support & Reorder',
                    style: const TextStyle(
                      color: AppColors.brandMaroon,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
