import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/services/cycle_analyzer.dart';

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
  // Get predictions from CycleAnalyzer (Phase 1 prediction engine)
  final predictions = await CycleAnalyzer.getCurrentPrediction();
  
  return PredictionData(
    periodDays: predictions['periodDays'] ?? {},
    predictedPeriodDays: predictions['predictedPeriodDays'] ?? {},
    fertileDays: predictions['fertileDays'] ?? {},
    ovulationDays: predictions['ovulationDays'] ?? {},
  );
});
