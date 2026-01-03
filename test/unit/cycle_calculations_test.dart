import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cycle Calculations', () {
    test('Current cycle day calculation is correct', () {
      final referenceDate = DateTime(2024, 1, 1);
      final currentDate = DateTime(2024, 1, 15);
      final averageCycleLength = 28;

      final daysSince = currentDate.difference(referenceDate).inDays;
      final cycleDay = (daysSince % averageCycleLength) + 1;

      expect(cycleDay, equals(15));
    });

    test('Next period date calculation is correct', () {
      final lastPeriodStart = DateTime(2024, 1, 1);
      final averageCycleLength = 28;

      final nextPeriodDate = lastPeriodStart.add(Duration(days: averageCycleLength));

      expect(nextPeriodDate, equals(DateTime(2024, 1, 29)));
    });

    test('Ovulation date is 14 days before next period', () {
      final nextPeriodDate = DateTime(2024, 1, 29);
      final ovulationDate = nextPeriodDate.subtract(const Duration(days: 14));

      expect(ovulationDate, equals(DateTime(2024, 1, 15)));
    });

    test('Fertile window includes 5 days before and including ovulation', () {
      final ovulationDate = DateTime(2024, 1, 15);
      final fertileWindowStart = ovulationDate.subtract(const Duration(days: 4));

      expect(fertileWindowStart, equals(DateTime(2024, 1, 11)));

      // Fertile window: Jan 11-15 (5 days total)
      final fertileWindowDuration =
          ovulationDate.difference(fertileWindowStart).inDays + 1;
      expect(fertileWindowDuration, equals(5));
    });

    test('Cycle phases are correctly determined', () {
      final lastPeriodStart = DateTime(2024, 1, 1);
      final periodLength = 5;
      // Average cycle length of 28 days used for cycle phase calculations

      // Menstrual phase: Days 1-5
      final menstrualEnd = lastPeriodStart.add(Duration(days: periodLength - 1));
      expect(menstrualEnd, equals(DateTime(2024, 1, 5)));

      // Follicular phase: Days 6-13
      final follicularStart = menstrualEnd.add(const Duration(days: 1));
      expect(follicularStart, equals(DateTime(2024, 1, 6)));

      // Ovulation: Day 14
      final ovulationDay = lastPeriodStart.add(const Duration(days: 13));
      expect(ovulationDay, equals(DateTime(2024, 1, 14)));

      // Luteal phase: Days 15-28
      final lutealStart = ovulationDay.add(const Duration(days: 1));
      expect(lutealStart, equals(DateTime(2024, 1, 15)));
    });

    test('Wrap around to next cycle works correctly', () {
      final lastPeriodStart = DateTime(2024, 1, 1);
      final currentDate = DateTime(2024, 2, 5); // 35 days later
      final averageCycleLength = 28;

      final daysSince = currentDate.difference(lastPeriodStart).inDays;
      final cycleDay = (daysSince % averageCycleLength) + 1;

      // Day 35 % 28 = 7, + 1 = 8
      expect(cycleDay, equals(8));
    });
  });
}
