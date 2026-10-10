import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/branch_model.dart';

/// Branch Comparison Bar Chart for Super Admin Dashboard
class BranchComparisonChart extends StatefulWidget {
  final List<BranchModel> branches;
  final bool isDark;

  const BranchComparisonChart({
    super.key,
    required this.branches,
    required this.isDark,
  });

  @override
  State<BranchComparisonChart> createState() => _BranchComparisonChartState();
}

class _BranchComparisonChartState extends State<BranchComparisonChart> {
  int? _touchedGroupIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.branches.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxRevenue = widget.branches
        .map((b) => b.revenue)
        .fold<double>(0.0, (prev, elem) => elem > prev ? elem : prev);
    final maxY = maxRevenue > 0 ? (maxRevenue * 1.3) : 5000.0;

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
                    'Branch Revenue Comparison',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gross revenue performance across all 5 branches',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Multi-Branch HQ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.purpleAccent,
                  ),
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
                      final branch = widget.branches[group.x.toInt()];
                      return BarTooltipItem(
                        '${branch.name}\n',
                        const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: 'Rs. ${branch.revenue.toStringAsFixed(0)}\n',
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '${branch.orderCount} total orders',
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
                        _touchedGroupIndex = null;
                      } else {
                        _touchedGroupIndex = response.spot!.touchedBarGroupIndex;
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
                        if (idx < 0 || idx >= widget.branches.length) {
                          return const SizedBox.shrink();
                        }
                        final branch = widget.branches[idx];
                        // Get short name (e.g., "F-7", "Blue Area")
                        final nameParts = branch.name.split(' ');
                        final shortName = nameParts.length > 2
                            ? '${nameParts[0]} ${nameParts[1]}'
                            : branch.name;

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            shortName,
                            style: TextStyle(
                              color: widget.isDark ? Colors.white60 : Colors.grey.shade700,
                              fontSize: 10,
                              fontWeight: _touchedGroupIndex == idx
                                  ? FontWeight.bold
                                  : FontWeight.w500,
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
                barGroups: List.generate(widget.branches.length, (i) {
                  final branch = widget.branches[i];
                  final isTouched = _touchedGroupIndex == i;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: branch.revenue > 0 ? branch.revenue : 50,
                        gradient: LinearGradient(
                          colors: isTouched
                              ? [const Color(0xFFEC4899), const Color(0xFF8B5CF6)]
                              : [
                                  const Color(0xFF7C3AED),
                                  const Color(0xFFA78BFA),
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 22,
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
