import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lunara/constants/app_colors.dart';
import 'package:lunara/providers/calendar_provider.dart';
import 'package:lunara/navigation/app_router.dart';
import 'package:lunara/widgets/calendar/daily_log_preview.dart';
import 'package:lunara/widgets/calendar/dashed_circle_painter.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final calendarStateAsync = ref.watch(calendarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              final now = DateTime.now();
              ref.read(calendarProvider.notifier).onDaySelected(now, now);
            },
            tooltip: 'Go to today',
          ),
          // Toggle format button
          IconButton(
            icon: Icon(
              _calendarFormat == CalendarFormat.month
                  ? Icons.calendar_view_week
                  : Icons.calendar_view_month,
            ),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.twoWeeks
                    : CalendarFormat.month;
              });
            },
            tooltip: 'Toggle View',
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: calendarStateAsync.when(
        data: (state) => Column(
          children: [
            _buildCalendar(state),
            _buildLegend(context),
            const Divider(height: 1),
            Expanded(child: DailyLogPreview(selectedDate: state.selectedDate)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: calendarStateAsync.maybeWhen(
        data: (state) => FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context)
                .pushNamed(
                  AppRoutes.dailyLog,
                  arguments: {'selectedDate': state.selectedDate},
                )
                .then((_) => ref.refresh(calendarProvider));
          },
          label: const Text('Edit Log'),
          icon: const Icon(Icons.edit),
        ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildCalendar(CalendarState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
      focusedDay: state.focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(state.selectedDate, day),
      onDaySelected: (selectedDay, focusedDay) {
        ref
            .read(calendarProvider.notifier)
            .onDaySelected(selectedDay, focusedDay);
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        // Defer state update to avoid updating during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(calendarProvider.notifier)
              .updateFocusedDay(focusedDay);
        });
      },

      // Styles
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false, // We use custom action button
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.primary),
        rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.primary),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        cellMargin: const EdgeInsets.all(4),
      ),
      rowHeight: 68,

      // Builders for custom day cells
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) =>
            _buildDayCell(context, day, state),
        todayBuilder: (context, day, focusedDay) =>
            _buildDayCell(context, day, state, isToday: true),
        selectedBuilder: (context, day, focusedDay) =>
            _buildDayCell(context, day, state, isSelected: true),
        outsideBuilder: (context, day, focusedDay) =>
            Opacity(opacity: 0.5, child: _buildDayCell(context, day, state)),
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime date,
    CalendarState state, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Check flags
    final hasPeriod = state.periodDays.contains(normalizedDate);
    final isPredicted = state.predictedPeriodDays.contains(normalizedDate);
    final isOvulation = state.ovulationDays.contains(normalizedDate);
    final isFertile = state.fertileDays.contains(normalizedDate);

    // Determine visualization
    Color? bgColor;
    Color? textColor;
    bool showDashedCircle = false;

    if (isSelected) {
      bgColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
    } else if (hasPeriod) {
      bgColor = AppColors.getPeriodColor(context);
      textColor = AppColors.getTextColorForBackground(bgColor);
    } else if (isOvulation) {
      // Flo uses text color + dashed border for Ovulation (using Gold as requested)
      textColor = AppColors.getOvulationDayColor(context);
      showDashedCircle = true;
    } else if (isFertile) {
      // Flo uses text color for Fertility window
      textColor = AppColors.getFollicularPhaseColor(context);
    } else if (isPredicted) {
      // Distinct background for predicted periods
      bgColor = AppColors.getPredictedPeriodColor(context);
      textColor = AppColors.getTextColorForBackground(bgColor);
    } else if (isToday) {
      // Subtle circle for today but not selected
      bgColor = colorScheme.primary.withValues(alpha: 0.15);
      textColor = colorScheme.primary;
    }

    final activity = state.sexualActivities[normalizedDate];
    final mood = state.moods[normalizedDate];

    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary : bgColor,
        shape: BoxShape.circle,
        border: isToday && !isSelected
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
      ),
      child: CustomPaint(
        painter: showDashedCircle
            ? DashedCirclePainter(
                color: AppColors.getOvulationDayColor(context),
                strokeWidth: 2.2,
              )
            : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Intimacy Icon (Shield Heart for protected, Normal Heart for unprotected)
            if (activity != null)
              Positioned(
                top: 6,
                child: Icon(
                  activity.protectionUsed
                      ? Icons.health_and_safety
                      : Icons.favorite,
                  size: 10,
                  color: isSelected
                      ? Colors.white
                      : AppColors.getSexualActivityLogColor(context),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isToday && !isSelected)
                  const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 6,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (textColor ?? colorScheme.onSurface),
                    fontWeight:
                        isSelected || isToday || hasPeriod || isOvulation
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: isToday ? 12 : 14,
                  ),
                ),
              ],
            ),
            // Mood Icon below the circle
            if (mood != null)
              Positioned(
                bottom: 6,
                child: Icon(
                  mood.moodType.icon,
                  size: 10,
                  color: isSelected
                      ? Colors.white
                      : AppColors.getMoodLogColor(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerDot(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendItem(
                color: AppColors.getPeriodColor(context),
                label: 'Period',
              ),
              _LegendItem(
                color: AppColors.getPredictedPeriodColor(context),
                label: 'Predicted',
              ),
              _LegendItem(
                color: AppColors.getOvulationDayColor(context),
                label: 'Ovulation',
              ),
              _LegendItem(
                color: AppColors.getFollicularPhaseColor(context),
                label: 'Fertility',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Secondary markers
          Row(
            children: [
              _buildMarkerDot(AppColors.getMoodLogColor(context)),
              const SizedBox(width: 4),
              Text(
                'Log',
                style: TextStyle(fontSize: 10, color: colorScheme.outline),
              ),
              const SizedBox(width: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary, width: 1.5),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Today',
                style: TextStyle(fontSize: 10, color: colorScheme.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
