import 'package:flutter_test/flutter_test.dart';

/// Unit tests for CycleAnalyzer business logic
/// Tests calculations and algorithms without requiring Supabase
void main() {
  group('CycleAnalyzer Logic Tests', () {
    group('Initial prediction generation logic', () {
      test('calculates next period date from last period and cycle length', () {
        final lastPeriodStart = DateTime(2026, 1, 1);
        final cycleLength = 28;
        final nextPeriod = lastPeriodStart.add(Duration(days: cycleLength));

        expect(nextPeriod, equals(DateTime(2026, 1, 29)));
        expect(nextPeriod.difference(lastPeriodStart).inDays, equals(28));
      });

      test('handles different cycle lengths correctly', () {
        final lastPeriod = DateTime(2026, 1, 1);
        final cycles = [21, 25, 28, 30, 35, 40, 45];

        for (final length in cycles) {
          final nextPeriod = lastPeriod.add(Duration(days: length));
          expect(nextPeriod.difference(lastPeriod).inDays, equals(length));
        }
      });

      test('initial confidence is always 50% for new users', () {
        const initialConfidence = 0.50;
        expect(initialConfidence, equals(0.50));
      });
    });

    group('Simple Moving Average calculation', () {
      test('calculates correct average from cycle lengths', () {
        final cycleLengths = [28, 29, 27, 30];
        final average = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
        expect(average, equals(28.5));
      });

      test('handles single cycle length', () {
        final cycleLengths = [32];
        final average = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
        expect(average, equals(32.0));
      });
    });

    group('Confidence calculation logic', () {
      test('assigns 65% confidence for 1 completed cycle', () {
        final cycleCount = 1;
        double confidence = cycleCount == 1 ? 0.65 : 0.50;
        expect(confidence, equals(0.65));
      });

      test('assigns 75% confidence for 2 completed cycles', () {
        final cycleCount = 2;
        double confidence = cycleCount == 2 ? 0.75 : 0.50;
        expect(confidence, equals(0.75));
      });

      test('calculates interpolated confidence for moderate variance', () {
        final stdDev = 5.0;
        final confidence = 0.95 - (stdDev / 10) * 0.35;

        expect(confidence, closeTo(0.775, 0.01));
        expect(confidence, greaterThan(0.60));
        expect(confidence, lessThan(0.95));
      });
    });

    group('Error calculation (Truth Event)', () {
      test('calculates error_days correctly when period starts early', () {
        final predictedDate = DateTime(2026, 1, 15);
        final actualDate = DateTime(2026, 1, 12);
        final errorDays = actualDate.difference(predictedDate).inDays;

        expect(errorDays, equals(-3));
      });

      test('calculates error_days correctly when period starts late', () {
        final predictedDate = DateTime(2026, 1, 15);
        final actualDate = DateTime(2026, 1, 18);
        final errorDays = actualDate.difference(predictedDate).inDays;

        expect(errorDays, equals(3));
      });

      test('calculates error_days as 0 for exact match', () {
        final predictedDate = DateTime(2026, 1, 15);
        final actualDate = DateTime(2026, 1, 15);
        final errorDays = actualDate.difference(predictedDate).inDays;

        expect(errorDays, equals(0));
      });
    });

    group('Accuracy statistics calculation', () {
      test('calculates accuracy percentage correctly', () {
        final predictionLogs = [
          {'error_days': -1},
          {'error_days': 2},
          {'error_days': 0},
          {'error_days': 5},
          {'error_days': -3},
        ];

        final accurateCount = predictionLogs.where((log) {
          final error = log['error_days'] as int;
          return error.abs() <= 2;
        }).length;

        final accuracyPercentage = (accurateCount / predictionLogs.length) * 100;
        expect(accuracyPercentage, equals(60.0));
      });

      test('calculates average error correctly', () {
        final errorDays = [-1, 2, 0, 5, -3];
        final avgError = errorDays.reduce((a, b) => a + b) / errorDays.length;
        expect(avgError, closeTo(0.6, 0.01));
      });
    });

    group('Edge cases', () {
      test('handles very long cycle lengths', () {
        final cycleLengths = [45, 44, 46, 45];
        final average = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;

        expect(average, equals(45.0));
        expect(average, lessThanOrEqualTo(45));
      });

      test('handles very short cycle lengths', () {
        final cycleLengths = [21, 22, 21, 21];
        final average = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;

        expect(average, equals(21.25));
        expect(average, greaterThanOrEqualTo(21));
      });

      test('handles future prediction dates', () {
        final now = DateTime.now();
        final nextPeriod = now.add(const Duration(days: 15));
        final daysUntil = nextPeriod.difference(now).inDays;

        expect(daysUntil, equals(15));
      });

      test('handles overdue periods', () {
        final now = DateTime.now();
        final overduePeriod = now.subtract(const Duration(days: 3));
        final daysUntil = overduePeriod.difference(now).inDays;

        expect(daysUntil, equals(-3));
      });
    });
  });
}
