import 'package:flutter/material.dart';
import 'package:food_fight/core/theme/admin_theme.dart';

/// Color-coded status badge for orders and active indicators
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AdminTheme.getStatusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmall ? 6 : 8,
            height: isSmall ? 6 : 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: isSmall ? 4 : 6),
          Text(
            _formatStatus(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: isSmall ? 11 : 12.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String s) {
    if (s.toLowerCase() == 'outfordelivery') return 'Out for Delivery';
    if (s.isEmpty) return 'Unknown';
    return s[0].toUpperCase() + s.substring(1);
  }
}
