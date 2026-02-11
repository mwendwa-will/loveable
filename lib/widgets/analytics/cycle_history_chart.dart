import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lunara/constants/app_colors.dart';
import 'package:lunara/models/period.dart';

class CycleHistoryChart extends StatelessWidget {
  final List<Period> cycles;

  const CycleHistoryChart({super.key, required this.cycles});

  @override
  Widget build(BuildContext context) {
    if (cycles.length < 2) {
      return Center(
        child: Text(
          'Log more cycles to see trends',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Prepare data: Calculate cycle lengths
    // List<int> lengths = ... derive from periods
    // For now, let's assume 'cycles' list implies finished periods which can determine cycle length
    // Actually, we need a list of cycle lengths. Let's compute them on the fly.

    final List<FlSpot> spots = [];
    for (int i = 0; i < cycles.length - 1; i++) {
      // Cycle length is diff between period starts
      final currentStart = cycles[i + 1].startDate;
      final nextStart = cycles[i].startDate; // Assuming descending order
      final days = nextStart.difference(currentStart).inDays;
      spots.add(FlSpot(i.toDouble(), days.toDouble()));
    }

    if (spots.isEmpty) return const SizedBox();

    return AspectRatio(
      aspectRatio: 1.70,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.primarySoft.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: AppColors.primarySoft.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ), // Could add dates
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: const Color(0xff37434d).withValues(alpha: 0.1),
            ),
          ),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 20, // Reasonable bounds for cycle length
          maxY: 40,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: AppColors.primaryGradient,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.3),
                    AppColors.primaryLight.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
