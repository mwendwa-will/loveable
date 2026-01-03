import 'package:flutter/material.dart';
import 'package:lovely/constants/app_colors.dart';

/// Centralized cycle calculation utilities
/// Used by both the calendar screen and home screen week strip
class CycleUtils {
  /// Get cycle phase information for a given date
  static CyclePhaseInfo getPhaseInfo({
    required DateTime date,
    required DateTime? referenceDate,
    required int averageCycleLength,
    required int averagePeriodLength,
    DateTime? currentPeriodStart,
  }) {
    if (referenceDate == null) {
      return CyclePhaseInfo(
        phase: CyclePhase.unknown,
        cycleDay: null,
      );
    }

    final daysSince = date.difference(referenceDate).inDays;
    final cycleDay = (daysSince % averageCycleLength) + 1;

    // Calculate next period date
    final cycleCount = (daysSince ~/ averageCycleLength) + 1;
    final nextPeriodDate = referenceDate.add(
      Duration(days: cycleCount * averageCycleLength),
    );

    // Check if date is in next period (PREDICTED)
    if (date.isAfter(nextPeriodDate.subtract(const Duration(days: 1))) &&
        date.isBefore(
          nextPeriodDate.add(Duration(days: averagePeriodLength)),
        )) {
      // This is a FUTURE predicted period
      return CyclePhaseInfo(
        phase: CyclePhase.predicted,
        cycleDay: cycleDay,
        isPredicted: true,
      );
    }

    // Calculate ovulation date (14 days before next period)
    final ovulationDate = nextPeriodDate.subtract(const Duration(days: 14));
    final fertileWindowStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileWindowEnd = ovulationDate;

    // Check current cycle phase
    if (cycleDay <= averagePeriodLength) {
      // Check if this is the current active period or a past period
      final isPredicted = currentPeriodStart != null && 
                         date.isAfter(currentPeriodStart.add(Duration(days: averagePeriodLength)));
      
      return CyclePhaseInfo(
        phase: CyclePhase.menstrual,
        cycleDay: cycleDay,
        isPredicted: isPredicted,
      );
    }

    // Check if it's ovulation day
    if (date.year == ovulationDate.year &&
        date.month == ovulationDate.month &&
        date.day == ovulationDate.day) {
      return CyclePhaseInfo(
        phase: CyclePhase.ovulation,
        cycleDay: cycleDay,
      );
    }

    // Check if it's in fertile window
    if ((date.isAfter(fertileWindowStart.subtract(const Duration(days: 1))) ||
            date.isAtSameMomentAs(fertileWindowStart)) &&
        (date.isBefore(fertileWindowEnd.add(const Duration(days: 1))) ||
            date.isAtSameMomentAs(fertileWindowEnd))) {
      return CyclePhaseInfo(
        phase: CyclePhase.follicular,
        cycleDay: cycleDay,
      );
    }

    // Follicular phase (after period, before ovulation)
    if (cycleDay > averagePeriodLength && cycleDay <= 13) {
      return CyclePhaseInfo(
        phase: CyclePhase.follicular,
        cycleDay: cycleDay,
      );
    }

    // Luteal phase (after ovulation)
    return CyclePhaseInfo(
      phase: CyclePhase.luteal,
      cycleDay: cycleDay,
    );
  }

  /// Get color for a cycle phase
  static Color getPhaseColor(
    CyclePhase phase,
    BuildContext context, {
    bool isNextCycle = false,
  }) {
    switch (phase) {
      case CyclePhase.menstrual:
        // Use calendar legend color for actual period
        return AppColors.getMenstrualPhaseColor(context);

      case CyclePhase.predicted:
        // Use calendar legend color for predicted period (pink)
        return AppColors.getLutealPhaseColor(context);

      case CyclePhase.follicular:
        // Use calendar legend color for follicular/fertile window
        return AppColors.getFollicularPhaseColor(context);

      case CyclePhase.ovulation:
        // Use calendar legend color for ovulation
        return AppColors.getOvulationDayColor(context);

      case CyclePhase.luteal:
        // Use calendar legend color for luteal phase
        return AppColors.getLutealPhaseColor(context);

      case CyclePhase.unknown:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  /// Get text color that contrasts with phase color
  static Color getPhaseTextColor(Color backgroundColor) {
    return AppColors.getTextColorForBackground(backgroundColor);
  }

  /// Normalize date to midnight (remove time component)
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Cycle phase information
class CyclePhaseInfo {
  final CyclePhase phase;
  final int? cycleDay;
  final bool isPredicted;

  CyclePhaseInfo({
    required this.phase,
    this.cycleDay,
    this.isPredicted = false,
  });
}

/// Cycle phases
enum CyclePhase {
  unknown,
  menstrual,
  predicted,  // Predicted future period
  follicular,
  ovulation,
  luteal,
}
