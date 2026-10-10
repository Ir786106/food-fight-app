import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Premium Donut Chart showing Order Fulfillment Status Proportions
class OrderStatusDonutChart extends StatefulWidget {
  final int deliveredCount;
  final int pendingCount;
  final int cancelledCount;
  final bool isDark;

  const OrderStatusDonutChart({
    super.key,
    required this.deliveredCount,
    required this.pendingCount,
    required this.cancelledCount,
    required this.isDark,
  });

  @override
  State<OrderStatusDonutChart> createState() => _OrderStatusDonutChartState();
}

class _OrderStatusDonutChartState extends State<OrderStatusDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.deliveredCount + widget.pendingCount + widget.cancelledCount;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    final deliveredPct = ((widget.deliveredCount / total) * 100).toStringAsFixed(0);
    final pendingPct = ((widget.pendingCount / total) * 100).toStringAsFixed(0);
    final cancelledPct = ((widget.cancelledCount / total) * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Distribution of order outcomes',
            style: TextStyle(
              fontSize: 12,
              color: widget.isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Pie Chart
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 3,
                          centerSpaceRadius: 42,
                          sections: [
                            if (widget.deliveredCount > 0)
                              PieChartSectionData(
                                color: const Color(0xFF10B981),
                                value: widget.deliveredCount.toDouble(),
                                title: '$deliveredPct%',
                                radius: _touchedIndex == 0 ? 38 : 32,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            if (widget.pendingCount > 0)
                              PieChartSectionData(
                                color: const Color(0xFFF59E0B),
                                value: widget.pendingCount.toDouble(),
                                title: '$pendingPct%',
                                radius: _touchedIndex == 1 ? 38 : 32,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            if (widget.cancelledCount > 0)
                              PieChartSectionData(
                                color: const Color(0xFFEF4444),
                                value: widget.cancelledCount.toDouble(),
                                title: '$cancelledPct%',
                                radius: _touchedIndex == 2 ? 38 : 32,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: widget.isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Orders',
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.isDark ? Colors.white54 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Legend
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      color: const Color(0xFF10B981),
                      title: 'Delivered',
                      count: widget.deliveredCount,
                      pct: deliveredPct,
                    ),
                    const SizedBox(height: 10),
                    _buildLegendItem(
                      color: const Color(0xFFF59E0B),
                      title: 'Pending/Active',
                      count: widget.pendingCount,
                      pct: pendingPct,
                    ),
                    const SizedBox(height: 10),
                    _buildLegendItem(
                      color: const Color(0xFFEF4444),
                      title: 'Cancelled',
                      count: widget.cancelledCount,
                      pct: cancelledPct,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String title,
    required int count,
    required String pct,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white70 : Colors.grey.shade800,
                ),
              ),
              Text(
                '$count orders ($pct%)',
                style: TextStyle(
                  fontSize: 10,
                  color: widget.isDark ? Colors.white38 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
