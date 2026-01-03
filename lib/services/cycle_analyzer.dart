import 'dart:math';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Handles cycle length calculations and predictions
/// Implements Instance 3 (First Forecast) and Instance 6 (Truth Event)
class CycleAnalyzer {
  static final _supabase = SupabaseService();

  /// Generate initial predictions for new users (Instance 3: First Forecast)
  /// Called after onboarding when user provides last period date
  static Future<void> generateInitialPredictions(String userId) async {
    try {
      final userData = await _supabase.getUserData();
      
      if (userData == null) {
        debugPrint('⚠️ User data not found');
        return;
      }
      
      final lastPeriodStart = DateTime.parse(userData['last_period_start']!);
      final cycleLength = userData['cycle_length'] as int;

      // Calculate first prediction using self-reported cycle length
      final nextPeriodDate = lastPeriodStart.add(Duration(days: cycleLength));

      // Store prediction with low confidence (50% - based on self-report)
      await _supabase.updateUserData({
        'next_period_predicted': nextPeriodDate.toIso8601String(),
        'prediction_confidence': 0.50,
        'prediction_method': 'self_reported',
        'average_cycle_length': cycleLength.toDouble(),
      });

      // Log this prediction for future accuracy tracking
      await _logPrediction(
        userId: userId,
        cycleNumber: 1,
        predictedDate: nextPeriodDate,
        confidence: 0.50,
        method: 'self_reported',
      );

      debugPrint(
          '✅ Initial prediction: ${nextPeriodDate.toLocal()} (${cycleLength}d cycle)');
    } catch (e) {
      debugPrint('❌ Error generating initial predictions: $e');
    }
  }

  /// Recalculate predictions based on actual logged periods (Instance 6: Truth Event)
  /// Called every time user starts a new period
  static Future<void> recalculateAfterPeriodStart(String userId) async {
    try {
      // Get all completed periods (sorted newest first)
      final periods = await _supabase.getCompletedPeriods(limit: 12);

      if (periods.isEmpty) {
        debugPrint('⚠️ No periods to analyze');
        return;
      }

      // Calculate cycle lengths from completed periods
      final cycleLengths = <int>[];
      for (int i = 0; i < periods.length - 1; i++) {
        final currentPeriod = periods[i];
        final nextPeriod = periods[i + 1];
        final cycleLength =
            nextPeriod.startDate.difference(currentPeriod.startDate).inDays;
        cycleLengths.add(cycleLength);
      }

      if (cycleLengths.isEmpty) {
        debugPrint(
            '⚠️ Need at least 2 periods to calculate cycle length - using default');
        // For first period, use self-reported data
        final userData = await _supabase.getUserData();
        
        if (userData == null) return;
        
        await generateInitialPredictions(userId);
        return;
      }

      // LEARNING ALGORITHM: Simple Moving Average (Phase 1)
      final averageCycleLength = _calculateSimpleAverage(cycleLengths);
      final confidence = _calculateConfidence(cycleLengths);

      // Get most recent period
      final lastPeriod = periods.first;
      final nextPredicted = lastPeriod.startDate
          .add(Duration(days: averageCycleLength.round()));

      // Update database
      await _supabase.updateUserData({
        'cycle_length': averageCycleLength.round(),
        'average_cycle_length': averageCycleLength,
        'next_period_predicted': nextPredicted.toIso8601String(),
        'prediction_confidence': confidence,
        'prediction_method': 'simple_average',
      });

      // Log the new prediction
      await _logPrediction(
        userId: userId,
        cycleNumber: cycleLengths.length + 1,
        predictedDate: nextPredicted,
        confidence: confidence,
        method: 'simple_average',
      );

      debugPrint(
          '✅ Recalculated: ${averageCycleLength.toStringAsFixed(1)} days avg, ${(confidence * 100).toStringAsFixed(0)}% confidence');
      debugPrint('   Next predicted: $nextPredicted');
    } catch (e) {
      debugPrint('❌ Error recalculating predictions: $e');
    }
  }

  /// Calculate simple average of cycle lengths
  static double _calculateSimpleAverage(List<int> cycleLengths) {
    if (cycleLengths.isEmpty) return 28.0;

    final sum = cycleLengths.reduce((a, b) => a + b);
    return sum / cycleLengths.length;
  }

  /// Calculate confidence based on variance
  /// Low variance = high confidence, High variance = low confidence
  static double _calculateConfidence(List<int> cycleLengths) {
    if (cycleLengths.length == 1) return 0.65; // Single data point
    if (cycleLengths.length == 2) return 0.75; // Two data points

    // Calculate standard deviation
    final mean = _calculateSimpleAverage(cycleLengths);
    final variance = cycleLengths
            .map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) /
        cycleLengths.length;

    final stdDev = sqrt(variance);

    // Map stdDev to confidence (inverse relationship)
    // stdDev < 2: 95% confidence (very regular)
    // stdDev = 5: 80% confidence (moderate)
    // stdDev > 10: 60% confidence (irregular)

    if (stdDev < 2) return 0.95;
    if (stdDev > 10) return 0.60;

    // Linear interpolation between 0.95 and 0.60
    return 0.95 - (stdDev / 10) * 0.35;
  }

  /// Log prediction for accuracy tracking
  static Future<void> _logPrediction({
    required String userId,
    required int cycleNumber,
    required DateTime predictedDate,
    required double confidence,
    required String method,
  }) async {
    try {
      await _supabase.client.from('prediction_logs').insert({
        'user_id': userId,
        'cycle_number': cycleNumber,
        'predicted_date': predictedDate.toIso8601String(),
        'confidence_at_prediction': confidence,
        'prediction_method': method,
      });
    } catch (e) {
      debugPrint('⚠️ Failed to log prediction: $e');
    }
  }

  /// Update prediction log when period actually starts (Truth Event)
  /// Records how accurate our prediction was
  static Future<void> recordPredictionAccuracy({
    required String userId,
    required int cycleNumber,
    required DateTime actualDate,
  }) async {
    try {
      // Find the prediction for this cycle
      final logs = await _supabase.client
          .from('prediction_logs')
          .select()
          .eq('user_id', userId)
          .eq('cycle_number', cycleNumber)
          .order('created_at', ascending: false)
          .limit(1);

      if (logs.isEmpty) {
        debugPrint('⚠️ No prediction log found for cycle $cycleNumber');
        return;
      }

      final log = logs.first;
      final predictedDate = DateTime.parse(log['predicted_date']);
      final errorDays = actualDate.difference(predictedDate).inDays;

      // Update the log
      await _supabase.client.from('prediction_logs').update({
        'actual_date': actualDate.toIso8601String(),
        'error_days': errorDays,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', log['id']);

      final accuracy = errorDays.abs();
      final timing = errorDays > 0 ? 'late' : errorDays < 0 ? 'early' : 'exact';

      debugPrint(
          '📊 Prediction accuracy: $accuracy day(s) $timing (cycle $cycleNumber)');
    } catch (e) {
      debugPrint('❌ Error recording accuracy: $e');
    }
  }

  /// Get prediction accuracy statistics
  static Future<Map<String, dynamic>> getPredictionStats(String userId) async {
    try {
      final logs = await _supabase.client
          .from('prediction_logs')
          .select()
          .eq('user_id', userId)
          .not('actual_date', 'is', null)
          .order('created_at', ascending: false);

      if (logs.isEmpty) {
        return {
          'total_predictions': 0,
          'average_error': 0.0,
          'accuracy_within_2_days': 0.0,
        };
      }

      final errors = logs.map((log) => (log['error_days'] as int).abs()).toList();
      final avgError = errors.reduce((a, b) => a + b) / errors.length;
      final within2Days = errors.where((e) => e <= 2).length / errors.length;

      return {
        'total_predictions': logs.length,
        'average_error': avgError,
        'accuracy_within_2_days': within2Days * 100,
      };
    } catch (e) {
      debugPrint('❌ Error getting stats: $e');
      return {};
    }
  }

  /// Get current prediction with all cycle phase dates
  /// Returns sets of dates for period, ovulation, and fertile window
  static Future<Map<String, Set<DateTime>>> getCurrentPrediction() async {
    try {
      final userData = await _supabase.getUserData();
      
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

      final averageCycleLength = (userData['average_cycle_length'] ?? 28.0).toDouble();
      final averagePeriodLength = userData['average_period_length'] ?? 5;

      debugPrint('🔢 Cycle Parameters:');
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
      
      // SAFEGUARD #1: For new users, show CURRENT cycle's ovulation/fertile window
      // (prevents Scenario #10: Dec 31 edge case where current cycle gets cut off)
      final currentCycleOvulation = lastPeriodStart.add(
        Duration(days: averageCycleLength.round() - 14),
      );
      
      // Add current cycle's ovulation (only if AFTER period ends and in range)
      if (currentCycleOvulation.isAfter(lastPeriodStart.add(Duration(days: averagePeriodLength - 1))) &&
          currentCycleOvulation.isAfter(startDate.subtract(const Duration(days: 1))) &&
          currentCycleOvulation.isBefore(endDate)) {
        ovulationDays.add(_normalizeDate(currentCycleOvulation));
        
        // Add current cycle's fertile window (5 days before ovulation, NOT including ovulation)
        for (int i = -5; i < 0; i++) {
          final fertileDay = currentCycleOvulation.add(Duration(days: i));
          if (fertileDay.isAfter(lastPeriodStart.add(Duration(days: averagePeriodLength - 1))) &&
              fertileDay.isAfter(startDate.subtract(const Duration(days: 1))) &&
              fertileDay.isBefore(endDate)) {
            fertileDays.add(_normalizeDate(fertileDay));
          }
        }
      }
      
      // SAFEGUARD #2: Generate predictions from lastPeriodStart onwards
      // This prevents ghost periods in history (Scenario #9)
      DateTime currentPrediction = lastPeriodStart;
      int cycleCount = 0;

      while (currentPrediction.isBefore(endDate)) {
        // Only show predictions from lastPeriodStart onwards
        if (currentPrediction.isAfter(startDate.subtract(const Duration(days: 1)))) {
          cycleCount++;
          
          // Add predicted period days for this cycle
          for (int i = 0; i < averagePeriodLength; i++) {
            final day = currentPrediction.add(Duration(days: i));
            if (day.isBefore(endDate)) {
              predictedPeriodDays.add(_normalizeDate(day));
            }
          }

          // Calculate ovulation for THIS cycle (14 days before NEXT period)
          final thisCycleOvulation = currentPrediction.add(
            Duration(days: averageCycleLength.round() - 14),
          );
          
          // Only add if it's AFTER the current period AND in range
          if (thisCycleOvulation.isAfter(currentPrediction.add(Duration(days: averagePeriodLength - 1))) &&
              thisCycleOvulation.isBefore(endDate)) {
            ovulationDays.add(_normalizeDate(thisCycleOvulation));

            // Add fertile window for THIS cycle (5 days before ovulation through ovulation)
            for (int i = -5; i <= 0; i++) {
              final fertileDay = thisCycleOvulation.add(Duration(days: i));
              if (fertileDay.isBefore(endDate) &&
                  fertileDay.isAfter(currentPrediction.add(Duration(days: averagePeriodLength - 1)))) {
                final normalizedFertile = _normalizeDate(fertileDay);
                if (!ovulationDays.contains(normalizedFertile)) {
                  fertileDays.add(normalizedFertile);
                }
              }
            }
          }
        }

        // Move to next cycle
        currentPrediction = currentPrediction.add(
          Duration(days: averageCycleLength.round()),
        );
      }

      debugPrint('📊 CycleAnalyzer predictions:');
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
      debugPrint('❌ Error getting current prediction: $e');
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
}
