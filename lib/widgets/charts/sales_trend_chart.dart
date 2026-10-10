import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../theme/app_theme.dart';

/// Premium Bar/Line Chart for Daily Revenue & Sales Volume
class SalesTrendChart extends StatefulWidget {
  final List<DailySalesStat> dailySales;
  final bool isDark;

  const SalesTrendChart({
    super.key,
    required this.dailySales,
    required this.isDark,
  });

  @override
  State<SalesTrendChart> createState() => _SalesTrendChartState();
}

class _SalesTrendChartState extends State<SalesTrendChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.dailySales.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxRevenue = widget.dailySales
        .map((s) => s.revenue)
        .fold<double>(0.0, (prev, elem) => elem > prev ? elem : prev);
    final maxY = maxRevenue > 0 ? (maxRevenue * 1.25) : 1000.0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Performance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Daily revenue trends across the selected period',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, size: 14, color: AppColors.primaryYellow),
                    SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => widget.isDark
                        ? const Color(0xFF0F172A)
                        : Colors.grey.shade900,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final stat = widget.dailySales[group.x.toInt()];
                      return BarTooltipItem(
                        '${stat.date.day}/${stat.date.month}\n',
                        const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: 'Rs. ${stat.revenue.toStringAsFixed(0)}\n',
                            style: const TextStyle(
                              color: AppColors.primaryYellow,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '${stat.ordersCount} orders',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.spot == null) {
                        _touchedIndex = null;
                      } else {
                        _touchedIndex = response.spot!.touchedBarGroupIndex;
                      }
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        String formatted;
                        if (value >= 1000) {
                          formatted = '${(value / 1000).toStringAsFixed(1)}k';
                        } else {
                          formatted = value.toStringAsFixed(0);
                        }
                        return Text(
                          formatted,
                          style: TextStyle(
                            color: widget.isDark ? Colors.white38 : Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= widget.dailySales.length) {
                          return const SizedBox.shrink();
                        }
                        // Skip labels if there are too many items to avoid overlap
                        final total = widget.dailySales.length;
                        if (total > 10 && idx % ((total / 6).ceil()) != 0) {
                          return const SizedBox.shrink();
                        }
                        final date = widget.dailySales[idx].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: TextStyle(
                              color: widget.isDark ? Colors.white54 : Colors.grey.shade600,
                              fontSize: 10,
                              fontWeight: _touchedIndex == idx
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(widget.dailySales.length, (i) {
                  final stat = widget.dailySales[i];
                  final isTouched = _touchedIndex == i;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: stat.revenue,
                        gradient: LinearGradient(
                          colors: isTouched
                              ? [const Color(0xFFFFB703), const Color(0xFFFB8500)]
                              : [
                                  const Color(0xFF0284C7),
                                  const Color(0xFF38BDF8),
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: widget.dailySales.length > 14 ? 10 : 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: widget.isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.grey.shade100,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
