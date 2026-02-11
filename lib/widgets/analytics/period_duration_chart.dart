import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lunara/constants/app_colors.dart';
import 'package:lunara/models/period.dart';

class PeriodDurationChart extends StatelessWidget {
  final List<Period> periods;

  const PeriodDurationChart({super.key, required this.periods});

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) {
      return const SizedBox();
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            enabled: false,
            touchTooltipData: BarTouchTooltipData(
              // tooltipBgColor: Colors.transparent, // Deprecated or changed in v0.66
              // padding: const EdgeInsets.all(0),
              // marginBottom: -10,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  rod.toY.round().toString(),
                  const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  // Show period start date
                  if (value.toInt() >= 0 && value.toInt() < periods.length) {
                    final p =
                        periods[periods.length -
                            1 -
                            value.toInt()]; // Reverse order
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${p.startDate.day}/${p.startDate.month}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(periods.length, (index) {
            final p =
                periods[periods.length -
                    1 -
                    index]; // Reverse so latest is right
            final duration = p.endDate != null
                ? p.endDate!.difference(p.startDate).inDays + 1
                : DateTime.now().difference(p.startDate).inDays + 1;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: duration.toDouble(),
                  gradient: AppColors.primaryGradient,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
              showingTooltipIndicators: [0],
            );
          }).take(7).toList(), // Only show last 7
        ),
      ),
    );
  }
}
