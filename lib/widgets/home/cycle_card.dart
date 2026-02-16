import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lunara/models/period.dart';
import 'package:lunara/constants/app_colors.dart';
import 'package:lunara/navigation/app_router.dart';
import 'package:lunara/widgets/home/cycle_progress_circle.dart';

class CycleCard extends StatelessWidget {
  final Period? currentPeriod;
  final DateTime? lastPeriodStart;
  final int averageCycleLength;
  final int averagePeriodLength;

  const CycleCard({
    super.key,
    required this.currentPeriod,
    required this.lastPeriodStart,
    required this.averageCycleLength,
    required this.averagePeriodLength,
  });

  @override
  Widget build(BuildContext context) {
    // Current cycle day calculation
    int? currentCycleDay;
    int? daysUntilPeriod;

    if (lastPeriodStart != null) {
      final now = DateUtils.dateOnly(DateTime.now());
      final daysSinceLastPeriod = now.difference(lastPeriodStart!).inDays;
      currentCycleDay = (daysSinceLastPeriod % averageCycleLength) + 1;

      // Calculate the next upcoming predicted period date
      final cyclesPassed = (daysSinceLastPeriod / averageCycleLength).ceil();
      final nextPeriodPredicted = lastPeriodStart!.add(
        Duration(days: cyclesPassed * averageCycleLength),
      );
      daysUntilPeriod = nextPeriodPredicted.difference(now).inDays;
      // If daysUntilPeriod is 0, the period is due today; keep as 0
    }

    final cycleStatus = _getCycleStatus(
      context,
      currentCycleDay,
      currentPeriod != null,
    );
    final statusColor = cycleStatus.color;
    final statusText = cycleStatus.text;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.calendar),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: 320,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Segmented Progress Circle
              CycleProgressCircle(
                currentCycleDay: currentCycleDay ?? 1,
                totalCycleDays: averageCycleLength,
                averagePeriodLength: averagePeriodLength,
                isPeriod: currentPeriod != null,
              ),

              // 2. Center Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (currentPeriod != null) ...[
                    Text(
                      'Period Day',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(DateTime.now().difference(currentPeriod!.startDate).inDays % averageCycleLength) + 1}',
                      style: GoogleFonts.outfit(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getMenstrualPhaseColor(context),
                        height: 1.0,
                      ),
                    ),
                  ] else if (daysUntilPeriod != null) ...[
                    Text(
                      daysUntilPeriod <= 0 ? 'Period Due' : 'Period in',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (daysUntilPeriod > 0)
                      Text(
                        '$daysUntilPeriod',
                        style: GoogleFonts.outfit(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          height: 1.0,
                        ),
                      )
                    else
                      Text(
                        'Today',
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getMenstrualPhaseColor(context),
                          height: 1.0,
                        ),
                      ),
                    if (daysUntilPeriod > 0)
                      Text(
                        daysUntilPeriod == 1 ? 'day' : 'days',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ] else ...[
                    Text(
                      'Day',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '--',
                      style: GoogleFonts.outfit(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                        height: 1.0,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _CycleStatusData _getCycleStatus(
    BuildContext context,
    int? cycleDay,
    bool isPeriod,
  ) {
    if (isPeriod) {
      return _CycleStatusData(
        color: AppColors.getMenstrualPhaseColor(context),
        text: 'Menstrual Phase',
        subtext: 'Time to rest and recharge',
      );
    }

    if (cycleDay == null) {
      return _CycleStatusData(
        color: AppColors.secondary,
        text: 'Tracking Paused',
        subtext: null,
      );
    }

    // Phase calculation matching CycleProgressCircle logic
    final ovulationDay = averageCycleLength - 14;
    final follicularEnd = ovulationDay - 5;

    if (cycleDay <= follicularEnd) {
      return _CycleStatusData(
        color: AppColors.getFollicularPhaseColor(context),
        text: 'Follicular Phase',
        subtext: 'Rising energy levels',
      );
    } else if (cycleDay <= ovulationDay) {
      return _CycleStatusData(
        color: AppColors.getOvulationDayColor(context),
        text: 'Ovulation window',
        subtext: 'Peak fertility',
      );
    } else {
      return _CycleStatusData(
        color: AppColors.getLutealPhaseColor(context),
        text: 'Luteal Phase',
        subtext: 'Winding down',
      );
    }
  }
}

class _CycleStatusData {
  final Color color;
  final String text;
  final String? subtext;

  _CycleStatusData({required this.color, required this.text, this.subtext});
}
