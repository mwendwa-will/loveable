import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/constants/app_colors.dart';
import 'package:lovely/services/health_service.dart';
import 'package:lovely/services/period_service.dart';
import 'package:lovely/services/cycle_analyzer.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/models/sexual_activity.dart';
import 'package:lovely/models/note.dart';
import 'package:lovely/utils/responsive_utils.dart';
import 'package:lovely/providers/daily_log_provider.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CalendarView();
  }
}

class _CalendarView extends ConsumerStatefulWidget {
  const _CalendarView();

  @override
  ConsumerState<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<_CalendarView> with SingleTickerProviderStateMixin {
  final _healthService = HealthService();
  final _periodService = PeriodService();
  late PageController _pageController;
  final int _currentPageIndex = 6; // Start at middle month (6 months back + current)
  final int _totalMonths = 12; // Show 12 months total
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now(); // Track selected date for daily log view
  bool _legendExpanded = false; // Collapsible legend
  DateTime? _highlightToday; // For today button animation
  late AnimationController _todayAnimationController;
  late Animation<double> _todayAnimation;

  // Memoized color cache to avoid repeated theme lookups
  final Map<String, Color> _colorCache = {};

  final Map<String, Future<CalendarData>> _calendarDataCache = {};

  @override
  void initState() {
    super.initState();
    // Clear cache to ensure fresh data after code changes
    _calendarDataCache.clear();
    _pageController = PageController(
      initialPage: _currentPageIndex,
      viewportFraction: 0.92,
    );
    
    // Today button animation
    _todayAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _todayAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _todayAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _todayAnimationController.dispose();
    super.dispose();
  }

  String _getCacheKey(DateTime start, DateTime end) {
    return '${start.year}-${start.month}-${start.day}_${end.year}-${end.month}-${end.day}';
  }

  Future<CalendarData> _loadCalendarDataCached(DateTime start, DateTime end) {
    final key = _getCacheKey(start, end);
    return _calendarDataCache.putIfAbsent(
      key,
      () => _loadCalendarData(start, end),
    );
  }

  DateTime _getMonthForPage(int pageIndex) {
    final validPageIndex = pageIndex.clamp(0, _totalMonths - 1);
    final monthsFromStart = validPageIndex - _currentPageIndex;
    final now = DateTime.now();
    return DateTime(now.year, now.month + monthsFromStart, 1);
  }

  void _goToToday() {
    _pageController.animateToPage(
      _currentPageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // Trigger today cell animation
    setState(() {
      _highlightToday = DateTime.now();
    });
    _todayAnimationController.forward(from: 0).then((_) {
      _todayAnimationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _highlightToday = null;
          });
        }
      });
    });
  }

  void _onPageChanged(int index) {
    if (index < 0 || index >= _totalMonths) {
      _pageController.jumpToPage(index.clamp(0, _totalMonths - 1));
      return;
    }

    final newMonth = _getMonthForPage(index);
    if (newMonth.month != _currentMonth.month ||
        newMonth.year != _currentMonth.year) {
      setState(() {
        _currentMonth = newMonth;
        // When navigating to a new month, select the first day of that month
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
        actions: [
          // Legend toggle button
          IconButton(
            icon: Icon(_legendExpanded ? Icons.info : Icons.info_outline),
            onPressed: () => setState(() => _legendExpanded = !_legendExpanded),
            tooltip: 'Toggle legend',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: 'Go to today',
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          _buildWeekdayHeaders(),
          Expanded(
            flex: 2,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical, // Vertical swipe for months
              onPageChanged: _onPageChanged,
              itemCount: _totalMonths,
              itemBuilder: (context, index) {
                final month = _getMonthForPage(index);
                return _buildMonthView(month);
              },
            ),
          ),
          // Daily log/agenda view for selected date
          Expanded(
            flex: 1,
            child: _buildDailyLogPreview(_selectedDate),
          ),
          // Collapsible legend with smooth resize
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _legendExpanded ? _buildLegend() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: const Row(
        children: [
          Expanded(child: _WeekdayHeaderCell(day: 'Sun')),
          Expanded(child: _WeekdayHeaderCell(day: 'Mon')),
          Expanded(child: _WeekdayHeaderCell(day: 'Tue')),
          Expanded(child: _WeekdayHeaderCell(day: 'Wed')),
          Expanded(child: _WeekdayHeaderCell(day: 'Thu')),
          Expanded(child: _WeekdayHeaderCell(day: 'Fri')),
          Expanded(child: _WeekdayHeaderCell(day: 'Sat')),
        ],
      ),
    );
  }

  Widget _buildMonthView(DateTime month) {
    final monthYear = DateFormat('MMMM yyyy').format(month);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                monthYear,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          Expanded(child: _buildCalendarGrid(month)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final startDate = firstDayOfMonth.subtract(Duration(days: firstWeekday));
    final totalDays = 42;

    return FutureBuilder<CalendarData>(
      future: _loadCalendarDataCached(
        startDate,
        startDate.add(Duration(days: totalDays)),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Couldn\'t load the calendar right now',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final data = snapshot.data ?? CalendarData.empty();

        return GridView.builder(
          padding: const EdgeInsets.all(4),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: context.responsive.calendarCellAspectRatio,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: totalDays,
          itemBuilder: (context, index) {
            final date = startDate.add(Duration(days: index));
            final isCurrentMonth = date.month == month.month;
            final isToday =
                _normalizeDate(date) == _normalizeDate(DateTime.now());

            return _buildDayCell(date, isCurrentMonth, isToday, data);
          },
        );
      },
    );
  }

  Widget _buildDayCell(
    DateTime date,
    bool isCurrentMonth,
    bool isToday,
    CalendarData data,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedDate = _normalizeDate(date);

    final hasPeriod = data.periodDays.contains(normalizedDate);
    final hasPredictedPeriod = data.predictedPeriodDays.contains(
      normalizedDate,
    );
    final isFertile = data.fertileDays.contains(normalizedDate);
    final isOvulation = data.ovulationDays.contains(normalizedDate);

    final hasMood = data.moods.containsKey(normalizedDate);
    final hasSymptoms = data.symptoms.containsKey(normalizedDate);
    final hasSexualActivity = data.sexualActivities.containsKey(normalizedDate);

    Color? backgroundColor;
    Color? textColor;
    Color? borderColor;

    if (hasPeriod) {
      backgroundColor = _getMemoizedColor(
        context,
        'menstrual_bg',
        () => AppColors.getMenstrualPhaseColor(context),
      );
      textColor = _getMemoizedColor(
        context,
        'menstrual_text',
        () => AppColors.getMenstrualTextColor(context),
      );
    } else if (hasPredictedPeriod) {
      backgroundColor = _getMemoizedColor(
        context,
        'luteal_bg',
        () => AppColors.getLutealPhaseColor(context),
      );
      textColor = _getMemoizedColor(
        context,
        'predicted_text',
        () => AppColors.getPredictedTextColor(context),
      );
    } else if (isOvulation) {
      backgroundColor = _getMemoizedColor(
        context,
        'ovulation_bg',
        () => AppColors.getOvulationDayColor(context),
      );
      textColor = _getMemoizedColor(
        context,
        'ovulation_text',
        () => AppColors.getOvulationTextColor(context),
      );
    } else if (isFertile) {
      backgroundColor = _getMemoizedColor(
        context,
        'fertile_bg',
        () => AppColors.getFollicularPhaseColor(context),
      );
      textColor = _getMemoizedColor(
        context,
        'fertile_text',
        () => AppColors.getFertileTextColor(context),
      );
    }

    if (isToday) {
      borderColor = colorScheme.primary;
    }

    // Check if today animation should apply
    final shouldAnimateToday = isToday && 
        _highlightToday != null && 
        _normalizeDate(_highlightToday!) == normalizedDate;

    Widget cell = GestureDetector(
      onTap: () {
        // Just update selected date - preview updates below
        setState(() {
          _selectedDate = date;
        });
      },
      onDoubleTap: () {
        // Double-tap to toggle period
        _togglePeriodForDate(date, hasPeriod, data);
      },
      onLongPress: () {
        // Long-press for inline quick actions
        _showInlineQuickActions(context, date, data);
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.surface,
          border: Border.all(
            color:
                borderColor ??
                colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: borderColor != null ? 2.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sexual activity indicator (top)
            SizedBox(
              height: 9,
              child: hasSexualActivity
                  ? _buildActivityIcon(
                      data.sexualActivities[normalizedDate]!,
                      colorScheme,
                    )
                  : const SizedBox.shrink(),
            ),
            // Date number (center)
            Text(
              '${date.day}',
              style: TextStyle(
                color: !isCurrentMonth
                    ? colorScheme.onSurface.withValues(alpha: 0.3)
                    : textColor ?? colorScheme.onSurface,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                fontSize: context.responsive.calendarDateFontSize,
              ),
            ),
            // Mood icon
            SizedBox(
              height: 11,
              child: hasMood
                  ? Icon(
                      data.moods[normalizedDate]!.moodType.icon,
                      size: context.responsive.calendarIconSize,
                      color: _getMoodColor(
                        data.moods[normalizedDate]!.moodType,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // Symptom dots
            SizedBox(
              height: 5,
              child: hasSymptoms
                  ? _buildSymptomDots(
                      data.symptoms[normalizedDate]!,
                      colorScheme,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );

    // Wrap with animation if needed
    if (shouldAnimateToday) {
      return AnimatedBuilder(
        animation: _todayAnimation,
        builder: (context, child) => Transform.scale(
          scale: _todayAnimation.value,
          child: child,
        ),
        child: cell,
      );
    }

    return cell;
  }

  Widget _buildActivityIcon(SexualActivity activity, ColorScheme colorScheme) {
    final iconSize = context.responsive.calendarActivityIconSize;
    if (activity.protectionUsed) {
      return Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.favorite,
            size: iconSize,
            color: colorScheme.error.withValues(alpha: 0.8),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: const EdgeInsets.all(0.5),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield,
                size: iconSize * 0.4,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      );
    }
    return Icon(
      Icons.favorite,
      size: iconSize,
      color: colorScheme.error.withValues(alpha: 0.8),
    );
  }

  Widget _buildSymptomDots(List<Symptom> symptoms, ColorScheme colorScheme) {
    if (symptoms.isEmpty) return const SizedBox.shrink();

    final count = symptoms.length.clamp(0, 3);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.5),
          child: Container(
            width: 2.5,
            height: 2.5,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return Colors.green;
      case MoodType.calm:
        return Colors.blue;
      case MoodType.tired:
        return Colors.grey;
      case MoodType.sad:
        return Colors.indigo;
      case MoodType.irritable:
        return Colors.orange;
      case MoodType.anxious:
        return Colors.purple;
      case MoodType.energetic:
        return Colors.amber;
    }
  }

  Widget _buildLegend() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Legend',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildLegendItem(
                AppColors.getMenstrualPhaseColor(context),
                'Period',
                textColor: AppColors.getMenstrualTextColor(context),
              ),
              _buildLegendItem(
                AppColors.getLutealPhaseColor(context),
                'Predicted',
                textColor: AppColors.getPredictedTextColor(context),
              ),
              _buildLegendItem(
                AppColors.getOvulationDayColor(context),
                'Ovulation',
                textColor: AppColors.getOvulationTextColor(context),
              ),
              _buildLegendItem(
                AppColors.getFollicularPhaseColor(context),
                'Fertile',
                textColor: AppColors.getFertileTextColor(context),
              ),
              _buildLegendItem(
                colorScheme.surface,
                'Today',
                border: colorScheme.primary,
                textColor: colorScheme.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Text(
            'Daily Logs',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildDotLegend(AppColors.getMoodLogColor(context), 'Mood'),
              _buildDotLegend(
                AppColors.getSymptomsLogColor(context),
                'Symptoms',
              ),
              _buildDotLegend(
                AppColors.getSexualActivityLogColor(context),
                'Activity',
              ),
              _buildDotLegend(AppColors.getNoteLogColor(context), 'Note'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    Color color,
    String label, {
    Color? border,
    Color? textColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            border: border != null
                ? Border.all(color: border, width: 2)
                : Border.all(
                    color: colorScheme.outline,
                    width: 1,
                  ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: border != null
              ? null
              : Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? colorScheme.onSurface,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDotLegend(Color color, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Future<CalendarData> _loadCalendarData(DateTime start, DateTime end) async {
    try {
      // Load periods
      final periods = await _periodService.getPeriodsInRange(
        startDate: start,
        endDate: end,
      );

      // Calculate period days
      final periodDays = <DateTime>{};
      for (final period in periods) {
        final periodStart = period.startDate;
        final periodEnd = period.endDate ?? DateTime.now();

        debugPrint('Period: ${period.id} from ${periodStart.toString()} to ${periodEnd.toString()}');
        
        for (int i = 0; i <= periodEnd.difference(periodStart).inDays; i++) {
          final day = _normalizeDate(
            DateTime(
              periodStart.year,
              periodStart.month,
              periodStart.day + i,
            ),
          );
          periodDays.add(day);
          debugPrint('  Adding period day: ${day.toString()}');
        }
      }

      debugPrint('Total period days loaded: ${periodDays.length}');
      debugPrint('Period days: ${periodDays.map((d) => DateFormat('MMM d').format(d)).join(', ')}');

      // Get predictions from CycleAnalyzer (Phase 1 prediction engine)
      final predictions = await CycleAnalyzer.getCurrentPrediction();
      final predictedPeriodDays = predictions['predictedPeriodDays'] ?? <DateTime>{};
      final fertileDays = predictions['fertileDays'] ?? <DateTime>{};
      final ovulationDays = predictions['ovulationDays'] ?? <DateTime>{};

      debugPrint('CycleAnalyzer predictions loaded:');
      debugPrint('   Predicted period days: ${predictedPeriodDays.length}');
      debugPrint('   Ovulation days: ${ovulationDays.length}');
      debugPrint('   Fertile days: ${fertileDays.length}');

      // Load daily logs in parallel using batch queries (performance optimization)
      final moods = <DateTime, Mood>{};
      final symptoms = <DateTime, List<Symptom>>{};
      final sexualActivities = <DateTime, SexualActivity>{};
      final notes = <DateTime, Note>{};

      // Use Future.wait to fetch all data in parallel instead of sequential loop
      final results = await Future.wait([
        _healthService.getMoodsInRange(startDate: start, endDate: end),
        _healthService.getSymptomsInRange(startDate: start, endDate: end),
        _healthService.getSexualActivitiesInRange(startDate: start, endDate: end),
        _healthService.getNotesInRange(startDate: start, endDate: end),
      ]);

      // Process moods - index-based data structure
      for (final mood in results[0] as List<Mood>) {
        moods[_normalizeDate(mood.date)] = mood;
      }

      // Process symptoms - index-based data structure
      for (final symptom in results[1] as List<Symptom>) {
        final normalizedDate = _normalizeDate(symptom.date);
        symptoms.putIfAbsent(normalizedDate, () => []).add(symptom);
      }

      // Process sexual activities - index-based data structure
      for (final activity in results[2] as List<SexualActivity>) {
        sexualActivities[_normalizeDate(activity.date)] = activity;
      }

      // Process notes - index-based data structure
      for (final note in results[3] as List<Note>) {
        notes[_normalizeDate(note.date)] = note;
      }

      return CalendarData(
        periodDays: periodDays,
        predictedPeriodDays: predictedPeriodDays,
        fertileDays: fertileDays,
        ovulationDays: ovulationDays,
        moods: moods,
        symptoms: symptoms,
        sexualActivities: sexualActivities,
        notes: notes,
      );
    } catch (e) {
      debugPrint('Error loading calendar data: $e');
      return CalendarData.empty();
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Daily log preview widget
  Widget _buildDailyLogPreview(DateTime date) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateKey = _normalizeDate(date);
    final isToday = _normalizeDate(date) == _normalizeDate(DateTime.now());
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Date header with gradient
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.primaryContainer.withValues(alpha: 0.7),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(date),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Daily logs content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  // Mood Section
                  _buildLogCard(
                    context,
                    ref.watch(moodStreamProvider(dateKey)),
                    icon: Icons.mood,
                    title: 'Mood',
                    emptyText: 'No mood logged',
                    builder: (mood) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getMoodColor(mood.moodType).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getMoodColor(mood.moodType).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          Icon(
                            mood.moodType.icon,
                            size: 18,
                            color: _getMoodColor(mood.moodType),
                          ),
                          Text(
                            mood.moodType.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _getMoodColor(mood.moodType),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Symptoms Section
                  _buildLogCard(
                    context,
                    ref.watch(symptomsStreamProvider(dateKey)),
                    icon: Icons.medical_services_outlined,
                    title: 'Symptoms',
                    emptyText: 'No symptoms logged',
                    builder: (symptoms) => Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: symptoms.map((s) {
                        final severity = (s.severity ?? 3).clamp(1, 5);
                        final severityLabel = ['Mild', 'Mild', 'Moderate', 'Severe', 'Severe'][severity - 1];
                        final severityColor = [
                          Colors.green,
                          Colors.green,
                          Colors.orange,
                          Colors.deepOrange,
                          Colors.red,
                        ][severity - 1];
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: severityColor.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              Text(
                                s.symptomType.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: severityColor.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  severityLabel,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: severityColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Sexual Activity Section
                  _buildLogCard(
                    context,
                    ref.watch(sexualActivityStreamProvider(dateKey)),
                    icon: Icons.favorite_outline,
                    title: 'Intimacy',
                    emptyText: 'No activity logged',
                    builder: (activity) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (activity.protectionUsed ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (activity.protectionUsed ? Colors.green : Colors.orange)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          Icon(
                            activity.protectionUsed ? Icons.health_and_safety_sharp : Icons.warning_amber_rounded,
                            size: 16,
                            color: activity.protectionUsed ? Colors.green : Colors.orange,
                          ),
                          Text(
                            activity.protectionUsed ? 'Protected' : 'Unprotected',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: activity.protectionUsed ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Notes Section
                  _buildLogCard(
                    context,
                    ref.watch(noteStreamProvider(dateKey)),
                    icon: Icons.note_outlined,
                    title: 'Notes',
                    emptyText: 'No notes',
                    builder: (note) => Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        note.content,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced log card builder
  Widget _buildLogCard<T>(
    BuildContext context,
    AsyncValue<T?> asyncValue,
    {
      required IconData icon,
      required String title,
      required String emptyText,
      required Widget Function(T data) builder,
    }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return asyncValue.when(
      data: (data) {
        if (data == null) {
          return Opacity(
            opacity: 0.5,
            child: Row(
              children: [
                Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Text(
                  emptyText,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            builder(data),
          ],
        );
      },
      loading: () => SizedBox(
        height: 24,
        child: Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
        ),
      ),
      error: (_, _) => Text(
        'Couldn\'t load this',
        style: TextStyle(fontSize: 11, color: colorScheme.error),
      ),
    );
  }

  // Toggle period for a date (double-tap action)
  Future<void> _togglePeriodForDate(DateTime date, bool hasPeriod, CalendarData data) async {
    HapticFeedback.mediumImpact();
    final dateKey = _normalizeDate(date);
    
    try {
      if (hasPeriod) {
        // Find and remove this date from period
        // For simplicity, we'll show a quick info that period can be edited via detail sheet
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tap to view period details for ${DateFormat('MMM d').format(date)}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Start a new period on this date
        await _periodService.startPeriod(startDate: dateKey);
        // Clear cache to refresh
        _calendarDataCache.clear();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t save that - try again?')),
        );
      }
    }
  }

  // Inline quick actions (long-press)
  void _showInlineQuickActions(BuildContext context, DateTime date, CalendarData data) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateKey = _normalizeDate(date);
    final currentMood = data.moods[dateKey];
    final currentSymptoms = data.symptoms[dateKey] ?? [];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              DateFormat('EEEE, MMM d').format(date),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            
            // Inline Mood Selector
            Text(
              'Mood',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: MoodType.values.map((moodType) {
                final isSelected = currentMood?.moodType == moodType;
                return GestureDetector(
                  onTap: () => _quickSaveMood(ctx, dateKey, moodType, currentMood),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getMoodColor(moodType).withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: _getMoodColor(moodType), width: 2)
                          : null,
                    ),
                    child: Icon(
                      moodType.icon,
                      size: 28,
                      color: _getMoodColor(moodType),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            
            // Inline Symptom Chips
            Text(
              'Symptoms',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SymptomType.values.map((symptomType) {
                final hasSymptom = currentSymptoms.any((s) => s.symptomType == symptomType);
                return FilterChip(
                  label: Text(symptomType.displayName),
                  selected: hasSymptom,
                  onSelected: (selected) => _quickToggleSymptom(
                    ctx, dateKey, symptomType, hasSymptom, currentSymptoms,
                  ),
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: hasSymptom ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            
            // Period toggle button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  final hasPeriod = data.periodDays.contains(dateKey);
                  _togglePeriodForDate(date, hasPeriod, data);
                },
                icon: Icon(
                  data.periodDays.contains(dateKey) 
                      ? Icons.water_drop 
                      : Icons.water_drop_outlined,
                ),
                label: Text(
                  data.periodDays.contains(dateKey) 
                      ? 'Period Logged' 
                      : 'Log Period Start',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.getMenstrualPhaseColor(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Quick save mood from inline selector
  Future<void> _quickSaveMood(
    BuildContext ctx,
    DateTime dateKey,
    MoodType moodType,
    Mood? currentMood,
  ) async {
    HapticFeedback.selectionClick();
    Navigator.pop(ctx);
    
    try {
      if (currentMood?.moodType == moodType) {
        // Same mood tapped = delete
        await _healthService.deleteMood(currentMood!.id);
      } else {
        // Save new mood
        await _healthService.saveMood(date: dateKey, mood: moodType);
      }
      // Clear cache and refresh
      _calendarDataCache.clear();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error saving mood: $e');
    }
  }

  // Quick toggle symptom from inline selector
  Future<void> _quickToggleSymptom(
    BuildContext ctx,
    DateTime dateKey,
    SymptomType symptomType,
    bool hasSymptom,
    List<Symptom> currentSymptoms,
  ) async {
    HapticFeedback.selectionClick();
    Navigator.pop(ctx);
    
    try {
      if (hasSymptom) {
        // Remove symptom
        final symptom = currentSymptoms.firstWhere((s) => s.symptomType == symptomType);
        await _healthService.deleteSymptom(symptom.id);
      } else {
        // Add symptom with default severity
        final types = [...currentSymptoms.map((s) => s.symptomType), symptomType];
        final severities = <SymptomType, int>{};
        for (var s in currentSymptoms) {
          severities[s.symptomType] = s.severity ?? 3;
        }
        severities[symptomType] = 3; // Default severity
        await _healthService.saveSymptoms(
          date: dateKey,
          symptomTypes: types,
          severities: severities,
        );
      }
      // Clear cache and refresh
      _calendarDataCache.clear();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error toggling symptom: $e');
    }
  }

  // Memoized color getter to avoid repeated theme context lookups
  Color _getMemoizedColor(
    BuildContext context,
    String key,
    Color Function() colorGetter,
  ) {
    return _colorCache.putIfAbsent(key, colorGetter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear color cache on theme changes
    _colorCache.clear();
  }
}

class CalendarData {
  final Set<DateTime> periodDays;
  final Set<DateTime> predictedPeriodDays;
  final Set<DateTime> fertileDays;
  final Set<DateTime> ovulationDays;
  final Map<DateTime, Mood> moods;
  final Map<DateTime, List<Symptom>> symptoms;
  final Map<DateTime, SexualActivity> sexualActivities;
  final Map<DateTime, Note> notes;

  CalendarData({
    required this.periodDays,
    required this.predictedPeriodDays,
    required this.fertileDays,
    required this.ovulationDays,
    required this.moods,
    required this.symptoms,
    required this.sexualActivities,
    required this.notes,
  });

  factory CalendarData.empty() {
    return CalendarData(
      periodDays: {},
      predictedPeriodDays: {},
      fertileDays: {},
      ovulationDays: {},
      moods: {},
      symptoms: {},
      sexualActivities: {},
      notes: {},
    );
  }
}

// Const widget for weekday headers (performance optimization)
class _WeekdayHeaderCell extends StatelessWidget {
  final String day;

  const _WeekdayHeaderCell({required this.day});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        day,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
