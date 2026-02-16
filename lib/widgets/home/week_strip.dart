import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/providers/calendar_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lunara/models/period.dart';
import 'package:lunara/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:lunara/widgets/calendar/dashed_circle_painter.dart';

class WeekStrip extends StatefulWidget {
  final DateTime? lastPeriodStart;
  final int averageCycleLength;
  final Period? currentPeriod;
  final Function(DateTime) onDateSelected;

  const WeekStrip({
    super.key,
    required this.lastPeriodStart,
    required this.averageCycleLength,
    required this.currentPeriod,
    required this.onDateSelected,
  });

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  int _weekOffset = 0; // 0 = current week
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 100);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getWeekLabel(int offset) {
    if (offset == 0) return 'This Week';
    if (offset == -1) return 'Last Week';
    if (offset == 1) return 'Next Week';

    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final targetWeekStart = currentWeekStart.add(Duration(days: offset * 7));
    final targetWeekEnd = targetWeekStart.add(const Duration(days: 6));

    if (targetWeekStart.year == targetWeekEnd.year) {
      if (targetWeekStart.month == targetWeekEnd.month) {
        return '${DateFormat('MMM d').format(targetWeekStart)} - ${DateFormat('d').format(targetWeekEnd)}';
      } else {
        return '${DateFormat('MMM d').format(targetWeekStart)} - ${DateFormat('MMM d').format(targetWeekEnd)}';
      }
    } else {
      return '${DateFormat('MMM d, yy').format(targetWeekStart)} - ${DateFormat('MMM d, yy').format(targetWeekEnd)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      100,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text(
                    _getWeekLabel(_weekOffset),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Calendar PageView
          SizedBox(
            height: 80,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _weekOffset = index - 100;
                });
              },
              itemBuilder: (context, index) {
                final weekOffset = index - 100;
                return _buildWeekContent(weekOffset, colorScheme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekContent(int weekOffset, ColorScheme colorScheme) {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final targetWeekStart = currentWeekStart.add(
      Duration(days: weekOffset * 7),
    );

    return Consumer(
      builder: (context, ref, child) {
        final calendarStateAsync = ref.watch(calendarProvider);

        return calendarStateAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (err, _) => Center(
            child: Icon(
              Icons.error_outline,
              size: 16,
              color: colorScheme.error,
            ),
          ),
          data: (state) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final day = targetWeekStart.add(Duration(days: index));
                final normalizedDate = DateTime(day.year, day.month, day.day);
                final isToday = DateUtils.isSameDay(normalizedDate, now);
                final isLoggedPeriod = state.periodDays.contains(
                  normalizedDate,
                );

                // Phase Visualization Logic
                Color? phaseColor;
                Color? textColor;
                bool showDashedCircle = false;

                if (isLoggedPeriod) {
                  phaseColor = AppColors.getPeriodColor(context);
                } else if (state.ovulationDays.contains(normalizedDate)) {
                  textColor = AppColors.getOvulationDayColor(context);
                  showDashedCircle = true;
                } else if (state.fertileDays.contains(normalizedDate)) {
                  textColor = AppColors.getFollicularPhaseColor(context);
                } else if (state.predictedPeriodDays.contains(normalizedDate)) {
                  phaseColor = AppColors.getPredictedPeriodColor(context);
                }

                textColor ??= (phaseColor != null
                    ? AppColors.getTextColorForBackground(phaseColor)
                    : colorScheme.onSurface);

                // Marker Checks
                final activity = state.sexualActivities[normalizedDate];
                final mood = state.moods[normalizedDate];

                return GestureDetector(
                  onTap: () => widget.onDateSelected(normalizedDate),
                  child: Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: phaseColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: CustomPaint(
                      painter: showDashedCircle
                          ? DashedCirclePainter(
                              color: AppColors.getOvulationDayColor(context),
                              strokeWidth: 1.5, // Thicker than previous 1.0
                              dashes: 15,
                            )
                          : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Intimacy Icon above the day label
                          if (activity != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: Icon(
                                activity.protectionUsed
                                    ? Icons.health_and_safety
                                    : Icons.favorite,
                                size: 9,
                                color: AppColors.getSexualActivityLogColor(
                                  context,
                                ),
                              ),
                            ),
                          Text(
                            DateFormat('E').format(day).substring(0, 1),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: textColor.withValues(alpha: 0.8),
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: isToday && phaseColor == null
                                ? BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  )
                                : null,
                            child: Text(
                              day.day.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: (isToday || showDashedCircle)
                                    ? FontWeight.bold
                                    : FontWeight.bold,
                                color: isToday && phaseColor == null
                                    ? colorScheme.onPrimary
                                    : textColor,
                              ),
                            ),
                          ),
                          // Mood Icon below the date circle
                          if (mood != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(
                                mood.moodType.icon,
                                size: 9,
                                color: AppColors.getMoodLogColor(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}
