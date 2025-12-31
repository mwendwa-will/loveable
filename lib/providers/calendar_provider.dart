import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/providers/period_provider.dart';

// Prediction calculations provider
class PredictionData {
  final Set<DateTime> periodDays;
  final Set<DateTime> predictedPeriodDays;
  final Set<DateTime> fertileDays;
  final Set<DateTime> ovulationDays;

  PredictionData({
    required this.periodDays,
    required this.predictedPeriodDays,
    required this.fertileDays,
    required this.ovulationDays,
  });
}

final predictionDataProvider = FutureProvider.autoDispose<PredictionData>((
  ref,
) async {
  final userData = await ref.watch(userDataProvider.future);

  final lastPeriodStart = userData?['last_period_start'] != null
      ? DateTime.parse(userData!['last_period_start'])
      : null;
  final averageCycleLength = userData?['average_cycle_length'] ?? 28;
  final averagePeriodLength = userData?['average_period_length'] ?? 5;

  final periodDays = <DateTime>{};
  final predictedPeriodDays = <DateTime>{};
  final fertileDays = <DateTime>{};
  final ovulationDays = <DateTime>{};

  // Calculate predictions
  if (lastPeriodStart != null) {
    final today = DateTime.now();
    final endDate = DateTime(today.year, today.month + 4, 1);
    DateTime currentPrediction = lastPeriodStart;

    while (currentPrediction.isBefore(endDate)) {
      if (currentPrediction.isAfter(today.subtract(const Duration(days: 1)))) {
        // Predicted period days
        for (int i = 0; i < averagePeriodLength; i++) {
          final day = currentPrediction.add(Duration(days: i));
          predictedPeriodDays.add(_normalizeDate(day));
        }

        // Ovulation
        final ovulationDate = currentPrediction.add(
          Duration(days: averageCycleLength - 14),
        );
        ovulationDays.add(_normalizeDate(ovulationDate));

        // Fertile window
        for (int i = -5; i <= 0; i++) {
          final fertileDay = ovulationDate.add(Duration(days: i));
          if (!ovulationDays.contains(_normalizeDate(fertileDay))) {
            fertileDays.add(_normalizeDate(fertileDay));
          }
        }
      }

      currentPrediction = currentPrediction.add(
        Duration(days: averageCycleLength),
      );
    }
  }

  return PredictionData(
    periodDays: periodDays,
    predictedPeriodDays: predictedPeriodDays,
    fertileDays: fertileDays,
    ovulationDays: ovulationDays,
  );
});

DateTime _normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
