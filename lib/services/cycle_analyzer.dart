import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:lunara/services/period_service.dart';
import 'package:lunara/services/profile_service.dart';

/// Engine that performs calculations and predictions. Accepts injected services
/// to make unit testing possible. The existing `CycleAnalyzer` static helpers
/// delegate to a default engine that uses the real services.
class CycleAnalyzerEngine {
  final PeriodService periodService;
  final ProfileService profileService;

  CycleAnalyzerEngine({
    PeriodService? periodService,
    ProfileService? profileService,
  }) : periodService = periodService ?? PeriodService(),
       profileService = profileService ?? ProfileService();

  // Public helpers (previously private)
  double calculateSimpleAverage(List<int> cycleLengths) {
    if (cycleLengths.isEmpty) return 28.0;
    final sum = cycleLengths.reduce((a, b) => a + b);
    return sum / cycleLengths.length;
  }

  double calculateConfidence(List<int> cycleLengths) {
    if (cycleLengths.length == 1) return 0.65;
    if (cycleLengths.length == 2) return 0.75;

    final mean = calculateSimpleAverage(cycleLengths);
    final variance =
        cycleLengths
            .map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) /
        cycleLengths.length;

    final stdDev = sqrt(variance);

    if (stdDev < 2) return 0.95;
    if (stdDev > 10) return 0.60;

    return 0.95 - (stdDev / 10) * 0.35;
  }

  double calculateVariability(List<int> cycleLengths) {
    if (cycleLengths.length <= 1) return 0.0;
    final mean = calculateSimpleAverage(cycleLengths);
    final variance =
        cycleLengths
            .map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) /
        cycleLengths.length;
    return sqrt(variance);
  }

  bool detectCycleShift({
    required double baseline,
    required double recent,
    required double variability,
  }) {
    final difference = (recent - baseline).abs();
    return difference > 2 && variability < 3;
  }

  // Other instance methods that use services remain as thin wrappers and can be
  // tested with injected fake services if needed. For now tests target the
  // pure calculation helpers above.
}

/// Backwards-compatible static facade used throughout the app.
class CycleAnalyzer {
  /// Generate initial predictions for new users (Instance 3: First Forecast)
  static Future<void> generateInitialPredictions(String userId) async {
    try {
      final userData = await _engine.profileService.getUserData();
      if (userData == null) {
        debugPrint('Warning: User data not found');
        return;
      }

      // Parse last period start safely
      final lastPeriodRaw = userData['last_period_start'];
      if (lastPeriodRaw == null) {
        debugPrint(
          'Warning: last_period_start missing; cannot generate initial predictions',
        );
        return;
      }
      final lastPeriodStart = DateTime.tryParse(lastPeriodRaw.toString());
      if (lastPeriodStart == null) {
        debugPrint('Warning: last_period_start parse failed: $lastPeriodRaw');
        return;
      }

      // Cycle length can be stored as int or numeric; fall back to average_cycle_length or default 28
      int cycleLength = 28;
      try {
        final raw =
            userData['cycle_length'] ?? userData['average_cycle_length'];
        if (raw is int) {
          cycleLength = raw;
        } else if (raw is double) {
          cycleLength = raw.round();
        } else if (raw is String) {
          cycleLength = int.tryParse(raw) ?? cycleLength;
        }
      } catch (_) {}

      final nextPeriodDate = lastPeriodStart.add(Duration(days: cycleLength));
      await _engine.profileService.updateUserData({
        'next_period_predicted': nextPeriodDate.toIso8601String(),
        'prediction_confidence': 0.50,
        'prediction_method': 'self_reported',
        'average_cycle_length': cycleLength,
      });
      debugPrint(
        'Initial prediction: ${nextPeriodDate.toLocal()} (${cycleLength}d cycle)',
      );
    } catch (e) {
      debugPrint('Error generating initial predictions: $e');
    }
  }

  /// Recalculate predictions using floating window approach
  static Future<void> recalculateAfterPeriodStart(String userId) async {
    try {
      final allPeriods = await _engine.periodService.getCompletedPeriods(
        limit: 12,
      );
      if (allPeriods.isEmpty) {
        debugPrint('Warning: No periods to analyze');
        return;
      }
      final allCycleLengths = <int>[];
      for (int i = 0; i < allPeriods.length - 1; i++) {
        final currentPeriod = allPeriods[i];
        final nextPeriod = allPeriods[i + 1];
        final cycleLength = nextPeriod.startDate
            .difference(currentPeriod.startDate)
            .inDays;
        allCycleLengths.add(cycleLength);
      }
      if (allCycleLengths.isEmpty) {
        await generateInitialPredictions(userId);
        return;
      }
      final windowSize = (allCycleLengths.length >= 6)
          ? 6
          : allCycleLengths.length;
      final recentCycleLengths = allCycleLengths.take(windowSize).toList();
      debugPrint('Cycle analysis: using last $windowSize cycles');
      debugPrint('   All cycles: $allCycleLengths');
      debugPrint('   Recent window: $recentCycleLengths');
      final recentAverageCycleLength = _calculateSimpleAverage(
        recentCycleLengths,
      );
      final recentConfidence = _calculateConfidence(recentCycleLengths);
      final userData = await _engine.profileService.getUserData();
      final baselineCycleLength = (userData?['cycle_length'] as int?) ?? 28;
      final variability = _calculateVariability(recentCycleLengths);
      final cycleShifted = _detectCycleShift(
        baseline: baselineCycleLength.toDouble(),
        recent: recentAverageCycleLength,
        variability: variability,
      );
      final lastPeriod = allPeriods.first;
      final nextPredicted = lastPeriod.startDate.add(
        Duration(days: recentAverageCycleLength.round()),
      );
      await _engine.profileService.updateUserData({
        'cycle_length': recentAverageCycleLength.round(),
        'average_cycle_length': recentAverageCycleLength.round(),
        'recent_average_cycle_length': recentAverageCycleLength,
        'baseline_cycle_length': baselineCycleLength.toDouble(),
        'cycle_variability': variability,
        'next_period_predicted': nextPredicted.toIso8601String(),
        'prediction_confidence': recentConfidence,
        'prediction_method': 'floating_window',
      });
      debugPrint('Recalculated (Floating Window):');
      debugPrint('   Baseline: ${baselineCycleLength.toStringAsFixed(1)} days');
      debugPrint(
        '   Recent: ${recentAverageCycleLength.toStringAsFixed(1)} days',
      );
      debugPrint('   Variability: ${variability.toStringAsFixed(2)}');
      if (cycleShifted) {
        debugPrint('   Warning: SHIFT DETECTED - cycle pattern changed');
      }
      debugPrint('   Next predicted: $nextPredicted');
      debugPrint(
        '   Confidence: ${(recentConfidence * 100).toStringAsFixed(0)}%',
      );
    } catch (e) {
      debugPrint('Error recalculating predictions: $e');
    }
  }

  /// Get prediction accuracy statistics
  static Future<Map<String, dynamic>> getPredictionStats(String userId) async {
    try {
      final logs = await _engine.periodService.getPredictionLogs(userId);
      final filtered = logs.where((l) => l['actual_date'] != null).toList();
      if (filtered.isEmpty) {
        return {
          'total_predictions': 0,
          'average_error': 0.0,
          'accuracy_within_2_days': 0.0,
        };
      }
      final errors = filtered
          .map((log) => (log['error_days'] as int).abs())
          .toList();
      final avgError = errors.reduce((a, b) => a + b) / errors.length;
      final within2Days = errors.where((e) => e <= 2).length / errors.length;
      return {
        'total_predictions': filtered.length,
        'average_error': avgError,
        'accuracy_within_2_days': within2Days * 100,
      };
    } catch (e) {
      debugPrint('Error getting stats: $e');
      return {};
    }
  }

  /// Update prediction log when period actually starts (Truth Event)
  static Future<void> recordPredictionAccuracy({
    required String userId,
    required int cycleNumber,
    required DateTime actualDate,
  }) async {
    try {
      final logs = await _engine.periodService.getLatestPredictionLog(
        userId: userId,
        cycleNumber: cycleNumber,
      );
      if (logs.isEmpty) {
        debugPrint('Warning: No prediction log found for cycle $cycleNumber');
        return;
      }
      final log = logs.first;
      final predictedDate = DateTime.parse(log['predicted_date']);
      final errorDays = actualDate.difference(predictedDate).inDays;
      await _engine.periodService.updatePredictionLog(log['id'].toString(), {
        'actual_date': actualDate.toIso8601String(),
        'error_days': errorDays,
        'updated_at': DateTime.now().toIso8601String(),
      });
      final accuracy = errorDays.abs();
      final timing = errorDays > 0
          ? 'late'
          : errorDays < 0
          ? 'early'
          : 'exact';
      debugPrint(
        'Prediction accuracy: $accuracy day(s) $timing (cycle $cycleNumber)',
      );
    } catch (e) {
      debugPrint('Error recording accuracy: $e');
    }
  }

  /// Record when a period is an anomaly (very different from usual)
  static Future<void> recordAnomalyIfNeeded({
    required String userId,
    required DateTime periodStartDate,
  }) async {
    try {
      final periods = await _engine.periodService.getCompletedPeriods(limit: 6);
      final cycleLengths = <int>[];
      for (int i = 0; i < periods.length - 1; i++) {
        final cycleLength = periods[i + 1].startDate
            .difference(periods[i].startDate)
            .inDays;
        cycleLengths.add(cycleLength);
      }
      if (cycleLengths.isEmpty) return;
      final recentAverage = _calculateSimpleAverage(cycleLengths);
      final variability = _calculateVariability(cycleLengths);
      final allPeriods = await _engine.periodService.getCompletedPeriods(
        limit: 10,
      );
      if (allPeriods.isEmpty) return;
      DateTime? lastPeriodStart;
      for (final period in allPeriods) {
        if (period.startDate.isBefore(periodStartDate)) {
          lastPeriodStart = period.startDate;
          break;
        }
      }
      if (lastPeriodStart == null) return;
      final cycleLength = periodStartDate.difference(lastPeriodStart).inDays;
      final deviation = (cycleLength - recentAverage).abs();
      final isAnomaly = deviation > (variability * 2);
      if (isAnomaly) {
        debugPrint(
          'ANOMALY DETECTED: $cycleLength days (avg: ${recentAverage.toStringAsFixed(1)}, stdDev: ${variability.toStringAsFixed(2)})',
        );
        try {
          await _engine.periodService.logAnomaly(
            userId: userId,
            periodDate: periodStartDate,
            cycleLength: cycleLength,
            averageCycle: recentAverage,
            variability: variability,
          );
          await _engine.periodService.incrementAnomalyCount(userId);
        } catch (e) {
          debugPrint('Warning: Failed to log anomaly: $e');
        }
      }
    } catch (e) {
      debugPrint('Warning: Error checking for anomaly: $e');
    }
  }

  static final _engine = CycleAnalyzerEngine();

  // Calculation helpers
  static double _calculateSimpleAverage(List<int> cycleLengths) =>
      _engine.calculateSimpleAverage(cycleLengths);
  static double _calculateConfidence(List<int> cycleLengths) =>
      _engine.calculateConfidence(cycleLengths);
  static double _calculateVariability(List<int> cycleLengths) =>
      _engine.calculateVariability(cycleLengths);
  static bool _detectCycleShift({
    required double baseline,
    required double recent,
    required double variability,
  }) => _engine.detectCycleShift(
    baseline: baseline,
    recent: recent,
    variability: variability,
  );

  /// Returns sets of dates for period, ovulation, and fertile window
  static Future<Map<String, Set<DateTime>>> getCurrentPrediction() async {
    try {
      final userData = await _engine.profileService.getUserData();
      if (userData == null) {
        return {
          'periodDays': <DateTime>{},
          'predictedPeriodDays': <DateTime>{},
          'ovulationDays': <DateTime>{},
          'fertileDays': <DateTime>{},
        };
      }

      final lastPeriodStart = userData['last_period_start'] != null
          ? DateTime.parse(userData['last_period_start'])
          : null;
      if (lastPeriodStart == null) {
        return {
          'periodDays': <DateTime>{},
          'predictedPeriodDays': <DateTime>{},
          'ovulationDays': <DateTime>{},
          'fertileDays': <DateTime>{},
        };
      }

      final averageCycleLength = (userData['average_cycle_length'] ?? 28)
          .toDouble();
      final averagePeriodLength = userData['average_period_length'] ?? 5;

      debugPrint('Cycle Parameters:');
      debugPrint('   Average cycle length: $averageCycleLength days');
      debugPrint('   Average period length: $averagePeriodLength days');
      debugPrint('   Last period start: $lastPeriodStart');

      final predictedPeriodDays = <DateTime>{};
      final ovulationDays = <DateTime>{};
      final fertileDays = <DateTime>{};

      // Generate predictions for entire calendar range (6 months back + 6 months forward)
      final today = DateTime.now();
      final startDate = DateTime(today.year, today.month - 6, 1);
      final endDate = DateTime(today.year, today.month + 6, 1);

      // Generate predictions from lastPeriodStart onwards
      DateTime currentPredictionCycle = lastPeriodStart;
      int cycleCount = 0;

      while (currentPredictionCycle.isBefore(endDate)) {
        if (currentPredictionCycle.isAfter(
          startDate.subtract(const Duration(days: 1)),
        )) {
          cycleCount++;

          // Only add to predictedPeriodDays for FUTURE cycles (not the currently logged one)
          // We consider it a future cycle if it starts after Today
          if (currentPredictionCycle.isAfter(
            today.subtract(const Duration(days: 1)),
          )) {
            for (int i = 0; i < averagePeriodLength; i++) {
              final day = currentPredictionCycle.add(Duration(days: i));
              if (day.isBefore(endDate)) {
                predictedPeriodDays.add(_normalizeDate(day));
              }
            }
          }

          // ALWAYS calculate ovulation and fertile window for every cycle in range
          final thisCycleOvulation = currentPredictionCycle.add(
            Duration(days: averageCycleLength.round() - 14),
          );

          if (thisCycleOvulation.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              thisCycleOvulation.isBefore(endDate)) {
            ovulationDays.add(_normalizeDate(thisCycleOvulation));

            // Fertile window (typically 5 days before ovulation + ovulation day)
            for (int i = -5; i <= 0; i++) {
              final fertileDay = thisCycleOvulation.add(Duration(days: i));
              if (fertileDay.isBefore(endDate) &&
                  fertileDay.isAfter(
                    startDate.subtract(const Duration(days: 1)),
                  )) {
                final normalizedFertile = _normalizeDate(fertileDay);
                if (!ovulationDays.contains(normalizedFertile)) {
                  fertileDays.add(normalizedFertile);
                }
              }
            }
          }
        }
        currentPredictionCycle = currentPredictionCycle.add(
          Duration(days: averageCycleLength.round()),
        );
      }

      debugPrint('CycleAnalyzer predictions:');
      debugPrint('   Cycles generated: $cycleCount');
      debugPrint('   Predicted periods: ${predictedPeriodDays.length} days');
      debugPrint('   Ovulation: ${ovulationDays.length} days');
      debugPrint('   Fertile: ${fertileDays.length} days');

      return {
        'periodDays': <DateTime>{},
        'predictedPeriodDays': predictedPeriodDays,
        'ovulationDays': ovulationDays,
        'fertileDays': fertileDays,
      };
    } catch (e) {
      debugPrint('Error getting current prediction: $e');
      return {
        'periodDays': <DateTime>{},
        'predictedPeriodDays': <DateTime>{},
        'ovulationDays': <DateTime>{},
        'fertileDays': <DateTime>{},
      };
    }
  }

  /// Normalize date to midnight for comparison
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // All standard static facade methods have been implemented above.
}
