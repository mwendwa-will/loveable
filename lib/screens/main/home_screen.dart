import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/providers/period_provider.dart';
import 'package:lovely/providers/daily_log_provider.dart';
import 'package:lovely/screens/main/profile_screen.dart';
import 'package:lovely/screens/daily_log_screen_v2.dart';
import 'package:lovely/screens/calendar_screen.dart';
import 'package:lovely/widgets/email_verification_banner.dart';
import 'package:lovely/widgets/day_detail_bottom_sheet.dart';
import 'package:lovely/models/period.dart';
import 'package:lovely/models/mood.dart';
import 'package:lovely/models/symptom.dart';
import 'package:lovely/models/sexual_activity.dart';
import 'package:lovely/constants/app_colors.dart';
import 'package:lovely/utils/responsive_utils.dart';
import 'package:lovely/services/cycle_analyzer.dart';
import 'package:intl/intl.dart';
import 'package:lovely/widgets/prediction_card.dart';
import 'package:lovely/core/feedback/feedback_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showVerificationRequired = false;
  Period? _currentPeriod;
  bool _isLoading = true;

  DateTime? _lastPeriodStart;
  int _averageCycleLength = 28;
  int _averagePeriodLength = 5;
  
  // Week navigation
  int _weekOffset = 0; // 0 = current week, -1 = last week, 1 = next week
  late PageController _weekPageController;

  @override
  void initState() {
    super.initState();
    _weekPageController = PageController(initialPage: 100); // Start in middle for infinite scroll
    _checkVerificationStatus();
    _loadData();
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    super.dispose();
  }

  void _checkVerificationStatus() {
    if (ref.read(supabaseServiceProvider).requiresVerification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _showVerificationRequired = true);
        }
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseServiceProvider);
      final userData = await supabase.getUserData();
      final currentPeriod = await supabase.getCurrentPeriod();

      if (mounted) {
        setState(() {
          _currentPeriod = currentPeriod;

          if (userData != null) {
            _lastPeriodStart = userData['last_period_start'] != null
                ? DateTime.parse(userData['last_period_start'])
                : null;
            _averageCycleLength = userData['average_cycle_length'] ?? 28;
            _averagePeriodLength = userData['average_period_length'] ?? 5;
          }
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _loadData: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        FeedbackService.showError(context, e);
      }
    }
  }

  void _showVerificationDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.tertiary),
            const SizedBox(width: 12),
            const Expanded(child: Text('Let\'s verify your email ✨')),
          ],
        ),
        content: const Text(
          'To keep your wellness journey secure and help you recover your account if needed, we\'d love for you to verify your email. It only takes a moment!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe later'),
          ),
          FilledButton.icon(
            onPressed: () async {
              try {
                final supabase = ref.read(supabaseServiceProvider);
                await supabase.resendVerificationEmail();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  FeedbackService.showSuccess(
                    context,
                    'Check your inbox! Verification email is on its way ✉️',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  FeedbackService.showError(context, e);
                }
              }
            },
            icon: const Icon(Icons.email_outlined, size: 18),
            label: const Text('Send Verification Email'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
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
          // Week header with navigation
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () {
                    _weekPageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
                GestureDetector(
                  onTap: () {
                    // Return to current week
                    _weekPageController.animateToPage(
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
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () {
                    _weekPageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
              ],
            ),
          ),
          // Swipeable week content
          SizedBox(
            height: 120,
            child: PageView.builder(
              controller: _weekPageController,
              onPageChanged: (page) {
                setState(() {
                  _weekOffset = page - 100;
                });
              },
              itemBuilder: (context, index) {
                final offset = index - 100;
                return _buildWeekContent(offset);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekLabel(int offset) {
    if (offset == 0) return 'This Week';
    if (offset == -1) return 'Last Week';
    if (offset == 1) return 'Next Week';
    
    final today = DateTime.now();
    final weekStart = today
        .subtract(Duration(days: today.weekday - 1))
        .add(Duration(days: offset * 7));
    return DateFormat('MMM d').format(weekStart);
  }

  Widget _buildWeekContent(int weekOffset) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final startOfWeek = today
        .subtract(Duration(days: today.weekday - 1))
        .add(Duration(days: weekOffset * 7));

    // SAFEGUARD: Load predictions once per week (prevent Scenario #4: PageView thrashing)
    // Use FutureBuilder instead of streams (prevent Scenario #7: memory leaks)
    return FutureBuilder<Map<String, Set<DateTime>>>(
      future: CycleAnalyzer.getCurrentPrediction(),
      builder: (context, predictionsSnapshot) {
        // SAFEGUARD #5: Graceful error handling (prevent Scenario #5: timeout cascades)
        // Return gray week on error to prevent cascade failures
        final predictions = predictionsSnapshot.data ?? {
          'predictedPeriodDays': <DateTime>{},
          'ovulationDays': <DateTime>{},
          'fertileDays': <DateTime>{},
        };

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final date = startOfWeek.add(Duration(days: index));
            final dateKey = DateTime(date.year, date.month, date.day);
            final normalizedDate = DateTime(date.year, date.month, date.day);
            final isToday =
                date.day == DateTime.now().day &&
                date.month == DateTime.now().month &&
                date.year == DateTime.now().year;

            // SAFEGUARD: Check logged periods FIRST (prevent Scenario #6: prediction override)
            Color phaseColor = colorScheme.surfaceContainerHighest; // Default
            
            // Priority 1: Check if date has logged period (from existing period stream)
            bool hasLoggedPeriod = false;
            if (_currentPeriod != null && _currentPeriod!.endDate == null) {
              final periodStart = _currentPeriod!.startDate;
              final normalizedPeriodStart = DateTime(periodStart.year, periodStart.month, periodStart.day);
              final daysSince = normalizedDate.difference(normalizedPeriodStart).inDays;
              hasLoggedPeriod = daysSince >= 0 && daysSince < _averagePeriodLength;
            }
            
            // Apply colors in priority order (matches calendar screen logic)
            if (hasLoggedPeriod) {
              phaseColor = AppColors.getMenstrualPhaseColor(context);
            }
            // Priority 2: Predicted period (only if no logged period)
            else if (predictions['predictedPeriodDays']!.contains(normalizedDate)) {
              phaseColor = AppColors.getLutealPhaseColor(context);
            }
            // Priority 3: Ovulation (only if no period)
            else if (predictions['ovulationDays']!.contains(normalizedDate)) {
              phaseColor = AppColors.getOvulationDayColor(context);
            }
            // Priority 4: Fertile window (only if no period/ovulation)
            else if (predictions['fertileDays']!.contains(normalizedDate)) {
              phaseColor = AppColors.getFollicularPhaseColor(context);
            }
            
            final textColor = AppColors.getTextColorForBackground(phaseColor);

            // Watch streams for this specific date
            final moodAsync = ref.watch(moodStreamProvider(dateKey));
            final symptomsAsync = ref.watch(symptomsStreamProvider(dateKey));
            final activityAsync = ref.watch(sexualActivityStreamProvider(dateKey));

            return Expanded(
              child: GestureDetector(
                onTap: () => DayDetailBottomSheet.show(context, dateKey),
                onLongPress: () => _showQuickAddMenu(dateKey),
                child: Column(
                  children: [
                    // Day letter
                    Text(
                      DateFormat('E').format(date).substring(0, 1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Sexual activity indicator
                    SizedBox(
                      height: 14,
                      child: activityAsync.when(
                        data: (activity) => activity != null
                            ? _buildActivityIndicator(activity, colorScheme)
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Date circle with phase color
                    Container(
                      width: context.responsive.weekStripCircleSize,
                      height: context.responsive.weekStripCircleSize,
                      decoration: BoxDecoration(
                        gradient: isToday
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  phaseColor,
                                  phaseColor.withValues(alpha: 0.7),
                                ],
                              )
                            : null,
                        color: isToday ? null : phaseColor,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: colorScheme.primary, width: 2.5)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          fontSize: context.responsive.weekStripDateFontSize,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Mood icon
                    SizedBox(
                      height: 18,
                      child: moodAsync.when(
                        data: (mood) => mood != null
                            ? Icon(
                                mood.moodType.icon,
                                size: context.responsive.weekStripMoodIconSize,
                                color: _getMoodColor(mood.moodType),
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Symptom dots
                    SizedBox(
                      height: 12,
                      child: symptomsAsync.when(
                        data: (symptoms) => _buildSymptomDots(symptoms, colorScheme),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  void _showQuickAddMenu(DateTime date) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quick log for ${DateFormat('MMM d').format(date)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAddButton(
                  ctx,
                  icon: Icons.mood,
                  label: 'Mood',
                  color: colorScheme.tertiary,
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyLogScreenV2(selectedDate: date),
                      ),
                    );
                  },
                ),
                _buildQuickAddButton(
                  ctx,
                  icon: Icons.medical_services,
                  label: 'Symptom',
                  color: colorScheme.secondary,
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyLogScreenV2(selectedDate: date),
                      ),
                    );
                  },
                ),
                _buildQuickAddButton(
                  ctx,
                  icon: Icons.favorite,
                  label: 'Activity',
                  color: colorScheme.error,
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyLogScreenV2(selectedDate: date),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomDots(List<Symptom> symptoms, ColorScheme colorScheme) {
    if (symptoms.isEmpty) return const SizedBox.shrink();
    
    final count = symptoms.length.clamp(0, 3);
    final dotSize = context.responsive.weekStripDotSize;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityIndicator(SexualActivity activity, ColorScheme colorScheme) {
    final iconSize = context.responsive.weekStripActivityIconSize;
    // Heart icon with optional shield overlay for protection
    if (activity.protectionUsed) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.favorite,
            size: iconSize,
            color: colorScheme.error.withValues(alpha: 0.8),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield,
                size: iconSize * 0.5,
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

  String _getCycleDisplayText(int? currentCycleDay) {
    // If actively menstruating, show period day
    if (_currentPeriod != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final periodStart = DateTime(
        _currentPeriod!.startDate.year,
        _currentPeriod!.startDate.month,
        _currentPeriod!.startDate.day,
      );
      
      // Check if today is within the period range
      bool isInPeriod = false;
      if (_currentPeriod!.endDate == null) {
        // Period is ongoing (not ended yet)
        isInPeriod = !today.isBefore(periodStart);
      } else {
        // Period has ended, check if today is within the range
        final periodEnd = DateTime(
          _currentPeriod!.endDate!.year,
          _currentPeriod!.endDate!.month,
          _currentPeriod!.endDate!.day,
        );
        isInPeriod = !today.isBefore(periodStart) && !today.isAfter(periodEnd);
      }
      
      if (isInPeriod) {
        final dayOfPeriod = today.difference(periodStart).inDays + 1;
        return 'Day $dayOfPeriod of period';
      }
    }
    
    // If we have cycle data (from period or onboarding), show cycle day
    if (currentCycleDay != null) {
      return 'Day $currentCycleDay of $_averageCycleLength';
    }
    
    // No tracking data at all
    return 'Let\'s begin your journey';
  }

  Widget _buildCycleCard() {
    final colorScheme = Theme.of(context).colorScheme;

    DateTime? referenceDate;
    if (_currentPeriod != null && _currentPeriod!.endDate == null) {
      referenceDate = _currentPeriod!.startDate;
    } else if (_lastPeriodStart != null) {
      referenceDate = _lastPeriodStart;
    }

    String? currentPeriodRange;
    int? currentCycleDay;

    if (referenceDate != null) {
      final daysSinceStart = DateTime.now().difference(referenceDate).inDays;
      currentCycleDay = (daysSinceStart % _averageCycleLength) + 1;

      if (_currentPeriod != null && _currentPeriod!.endDate == null) {
        currentPeriodRange =
            '${DateFormat('MMM d').format(referenceDate)} - ongoing';
      }

      if (_currentPeriod != null && _currentPeriod!.endDate != null) {
        currentPeriodRange =
            '${DateFormat('MMM d').format(_currentPeriod!.startDate)} - ${DateFormat('MMM d').format(_currentPeriod!.endDate!)}';
      }
    }

    // Use theme-aware period color from AppColors
    final periodColor = AppColors.getPeriodColor(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            periodColor.withValues(alpha: 0.1),
            colorScheme.surfaceContainerHighest,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Cycle ✨',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, size: 20),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _showCyclePhaseInfo(context, currentCycleDay),
                tooltip: 'Learn about your cycle phase',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getCycleDisplayText(currentCycleDay),
            style: TextStyle(
              fontSize: 32,
              color: currentCycleDay != null || _currentPeriod != null || _lastPeriodStart != null 
                  ? colorScheme.onSurface 
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (currentCycleDay != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (currentCycleDay - 1) / _averageCycleLength,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(periodColor),
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Use CycleAnalyzer for predictions instead of manual calculation
          FutureBuilder<Map<String, Set<DateTime>>>(
            future: CycleAnalyzer.getCurrentPrediction(),
            builder: (context, snapshot) {
              // Handle loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Handle error state
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'We couldn\'t load predictions right now',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              // Handle empty/null data
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }

              final predictions = snapshot.data!;
              final predictedPeriodDays = predictions['predictedPeriodDays'] ?? <DateTime>{};
              final ovulationDays = predictions['ovulationDays'] ?? <DateTime>{};
              final fertileDays = predictions['fertileDays'] ?? <DateTime>{};

              // Find next predicted period (first date after today)
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              
              final allPredictedPeriods = predictedPeriodDays.toList()..sort();
              final futureOvulation = ovulationDays
                  .where((date) => date.isAfter(today) || date.isAtSameMomentAs(today))
                  .toList()
                ..sort();

              final futureFertile = fertileDays
                  .where((date) => date.isAfter(today) || date.isAtSameMomentAs(today))
                  .toList()
                ..sort();

              // Find next period START (not just next period day)
              // We need to skip the current period and find when the NEXT period starts
              DateTime? nextPeriodStart;
              if (allPredictedPeriods.isNotEmpty) {
                for (int i = 0; i < allPredictedPeriods.length; i++) {
                  final currentDate = allPredictedPeriods[i];
                  
                  // Skip past and today's dates
                  if (!currentDate.isAfter(today)) continue;
                  
                  // Check if this is a period start (no period day immediately before it)
                  final isPeriodStart = i == 0 || 
                      currentDate.difference(allPredictedPeriods[i - 1]).inDays > 1;
                  
                  if (isPeriodStart) {
                    nextPeriodStart = currentDate;
                    break;
                  }
                }
              }

              // Find next consecutive fertile window (not all fertile days across cycles)
              DateTime? fertileStart;
              DateTime? fertileEnd;
              if (futureFertile.isNotEmpty) {
                fertileStart = futureFertile.first;
                fertileEnd = futureFertile.first;
                
                // Find consecutive days starting from first fertile day
                for (int i = 1; i < futureFertile.length; i++) {
                  final currentDate = futureFertile[i];
                  final previousDate = futureFertile[i - 1];
                  
                  // Check if dates are consecutive (1 day apart)
                  if (currentDate.difference(previousDate).inDays == 1) {
                    fertileEnd = currentDate;
                  } else {
                    // Gap found, stop here
                    break;
                  }
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (nextPeriodStart != null) ...[
                    _buildPredictionRow(
                      icon: Icons.water_drop_outlined,
                      label: 'Your next period looks like',
                      date: DateFormat('E, MMM d').format(nextPeriodStart),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_currentPeriod != null || currentPeriodRange != null) ...[
                    _buildPredictionRow(
                      icon: Icons.favorite_outline,
                      label: 'Current period',
                      date: currentPeriodRange ?? 'Not yet tracked',
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fertileStart != null && fertileEnd != null) ...[
                    _buildPredictionRow(
                      icon: Icons.eco_outlined,
                      label: 'Your fertile window',
                      date: '${DateFormat('MMM d').format(fertileStart)} - ${DateFormat('MMM d').format(fertileEnd)}',
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (futureOvulation.isNotEmpty)
                    _buildPredictionRow(
                      icon: Icons.star_outline,
                      label: 'Ovulation day coming up',
                      date: DateFormat('E, MMM d').format(futureOvulation.first),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionRow({
    required IconData icon,
    required String label,
    required String date,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final moodAsync = ref.watch(moodStreamProvider(todayKey));
    final currentMood = moodAsync.value;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.mood,
                  size: 20,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'How are you feeling today?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Inline mood grid - 1 tap to select
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: MoodType.values.map((moodType) {
              final isSelected = currentMood?.moodType == moodType;
              final moodColor = _getMoodColor(moodType);
              
              return GestureDetector(
                onTap: () => _quickToggleMood(moodType, currentMood),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? moodColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isSelected 
                        ? Border.all(color: moodColor, width: 2)
                        : null,
                  ),
                  child: Icon(
                    moodType.icon,
                    size: 28,
                    color: isSelected 
                        ? moodColor 
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              );
            }).toList(),
          ),
          // Show selected mood label
          if (currentMood != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                currentMood.moodType.displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _getMoodColor(currentMood.moodType),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Quick toggle mood - 1 tap
  Future<void> _quickToggleMood(MoodType moodType, Mood? currentMood) async {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    
    try {
      final supabase = ref.read(supabaseServiceProvider);
      
      if (currentMood?.moodType == moodType) {
        // Tapped same mood = delete
        await supabase.deleteMood(currentMood!.id);
      } else {
        // Tapped different mood = save new
        await supabase.saveMood(date: todayKey, mood: moodType);
      }
      ref.invalidate(moodStreamProvider(todayKey));
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, 'Couldn\'t save that - try again?');
      }
    }
  }

  Widget _buildSymptomsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final symptomsAsync = ref.watch(symptomsStreamProvider(todayKey));
    final currentSymptoms = symptomsAsync.value ?? [];
    final loggedTypes = currentSymptoms.map((s) => s.symptomType).toSet();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medical_services_outlined,
                  size: 20,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'What you\'re experiencing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Inline symptom chips - tap to toggle
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SymptomType.values.map((symptomType) {
              final isSelected = loggedTypes.contains(symptomType);
              final symptom = isSelected
                  ? currentSymptoms.firstWhere((s) => s.symptomType == symptomType)
                  : null;
              final symptomColor = _getSymptomColor(symptomType);

              return GestureDetector(
                onTap: () => _quickToggleSymptom(symptomType, symptom, currentSymptoms),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? symptomColor.withValues(alpha: 0.2) 
                        : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: symptomColor, width: 2)
                        : Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        symptomType.icon,
                        size: 16,
                        color: isSelected ? symptomColor : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        symptomType.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? symptomColor : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isSelected && symptom?.severity != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: symptomColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${symptom!.severity}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: symptomColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getSymptomColor(SymptomType symptom) {
    switch (symptom) {
      case SymptomType.cramps:
        return Colors.red;
      case SymptomType.headache:
        return Colors.purple;
      case SymptomType.fatigue:
        return Colors.blueGrey;
      case SymptomType.bloating:
        return Colors.blue;
      case SymptomType.nausea:
        return Colors.green;
      case SymptomType.backPain:
        return Colors.brown;
      case SymptomType.breastTenderness:
        return Colors.pink;
      case SymptomType.acne:
        return Colors.orange;
    }
  }

  // Quick toggle symptom with severity picker
  Future<void> _quickToggleSymptom(
    SymptomType symptomType,
    Symptom? existingSymptom,
    List<Symptom> allSymptoms,
  ) async {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    
    if (existingSymptom != null) {
      // Tapped selected symptom = show severity picker or remove
      _showSymptomSeverityPicker(
        symptomType: symptomType,
        existingSymptom: existingSymptom,
        currentSeverity: existingSymptom.severity ?? 3,
        allSymptoms: allSymptoms,
        todayKey: todayKey,
      );
    } else {
      // Tapped unselected symptom = show severity picker to add
      _showSymptomSeverityPicker(
        symptomType: symptomType,
        existingSymptom: null,
        currentSeverity: 3,
        allSymptoms: allSymptoms,
        todayKey: todayKey,
      );
    }
  }

  void _showSymptomSeverityPicker({
    required SymptomType symptomType,
    required Symptom? existingSymptom,
    required int currentSeverity,
    required List<Symptom> allSymptoms,
    required DateTime todayKey,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final symptomColor = _getSymptomColor(symptomType);
    final isNewSymptom = existingSymptom == null;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(symptomType.icon, color: symptomColor),
                const SizedBox(width: 8),
                Text(
                  'How intense is it?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final level = index + 1;
                final isSelected = currentSeverity == level;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _saveSymptomWithSeverity(
                      symptomType: symptomType,
                      severity: level,
                      existingSymptom: existingSymptom,
                      allSymptoms: allSymptoms,
                      todayKey: todayKey,
                    );
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? symptomColor
                              : symptomColor.withValues(alpha: 0.15),
                          border: Border.all(
                            color: symptomColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$level',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : symptomColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSeverityLabel(level),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            if (!isNewSymptom)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _removeSymptom(existingSymptom, todayKey);
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove this'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getSeverityLabel(int level) {
    switch (level) {
      case 1: return 'Mild';
      case 2: return 'Light';
      case 3: return 'Mod';
      case 4: return 'Strong';
      case 5: return 'Severe';
      default: return '';
    }
  }

  Future<void> _saveSymptomWithSeverity({
    required SymptomType symptomType,
    required int severity,
    required Symptom? existingSymptom,
    required List<Symptom> allSymptoms,
    required DateTime todayKey,
  }) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final currentTypes = allSymptoms.map((s) => s.symptomType).toList();
      final severities = <SymptomType, int>{};
      
      for (var s in allSymptoms) {
        if (s.symptomType == symptomType) {
          severities[s.symptomType] = severity;
        } else {
          severities[s.symptomType] = s.severity ?? 3;
        }
      }
      
      if (existingSymptom == null) {
        // Adding new symptom
        severities[symptomType] = severity;
        await supabase.saveSymptoms(
          date: todayKey,
          symptomTypes: [...currentTypes, symptomType],
          severities: severities,
        );
      } else {
        // Updating existing symptom
        await supabase.saveSymptoms(
          date: todayKey,
          symptomTypes: currentTypes,
          severities: severities,
        );
      }
      
      ref.invalidate(symptomsStreamProvider(todayKey));
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, 'Couldn\'t save that - try again?');
      }
    }
  }

  Future<void> _removeSymptom(Symptom symptom, DateTime todayKey) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.deleteSymptom(symptom.id);
      ref.invalidate(symptomsStreamProvider(todayKey));
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, 'Couldn\'t remove that - try again?');
      }
    }
  }

  Widget _buildDailyTip() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.tertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: colorScheme.onTertiary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wellness Tip 💡',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your body is amazing! Stay hydrated and rest well - you deserve it.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final supabase = ref.read(supabaseServiceProvider);
    final isEmailVerified = supabase.isEmailVerified;
    final greeting = _getGreeting();
    final cycleStatus = _getCycleStatus();

    if (_showVerificationRequired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showVerificationDialog();
        setState(() => _showVerificationRequired = false);
      });
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: Theme.of(context).textTheme.titleLarge),
              Text('Loading...', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.person, color: colorScheme.onPrimary, size: 20),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: Theme.of(context).textTheme.titleLarge),
            Text(
              cycleStatus,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
            tooltip: 'Calendar',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(colorScheme),
      body: Column(
        children: [
          if (!isEmailVerified) const EmailVerificationBanner(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildWeekStrip(),
                  const PredictionCard(), // ✨ NEW: Show prediction with confidence
                  _buildCycleCard(),
                  _buildMoodSection(),
                  _buildSymptomsSection(),
                  _buildDailyTip(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getCycleStatus() {
    if (_currentPeriod != null && _currentPeriod!.endDate == null) {
      final daysSince =
          DateTime.now().difference(_currentPeriod!.startDate).inDays + 1;
      return 'Day $daysSince of period';
    } else if (_lastPeriodStart != null) {
      final today = DateTime.now();
      final daysSince = today.difference(_lastPeriodStart!).inDays;
      final cycleDay = (daysSince % _averageCycleLength) + 1;
      return 'Day $cycleDay of $_averageCycleLength-day cycle';
    }
    return 'Ready to track your wellness?';
  }

  Widget? _buildFloatingActionButton(ColorScheme colorScheme) {
    // Always show "Log Today" - users can log ANY data (mood, symptoms, sexual activity, notes, period)
    // regardless of period status. No restrictions!
    return FloatingActionButton.extended(
      onPressed: () {
        final today = DateTime.now();
        final todayKey = DateTime(today.year, today.month, today.day);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DailyLogScreenV2(selectedDate: todayKey),
          ),
        );
      },
      icon: const Icon(Icons.edit_note),
      label: const Text('Log Today'),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    );
  }

  // Show cycle phase information
  void _showCyclePhaseInfo(BuildContext context, int? currentCycleDay) {
    if (currentCycleDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Track your first period to unlock personalized cycle insights ✨'),
        ),
      );
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    late String phaseTitle;
    late String phaseDescription;
    late Color phaseColor;

    if (currentCycleDay <= 5) {
      phaseTitle = 'Menstrual Phase';
      phaseDescription = 'Your body is renewing itself. This is the perfect time to slow down, be gentle with yourself, and honor what you need.';
      phaseColor = AppColors.getMenstrualPhaseColor(context);
    } else if (currentCycleDay <= 13) {
      phaseTitle = 'Follicular Phase';
      phaseDescription = 'Your energy is rising! This is your time to shine - embrace new challenges, start creative projects, and ride this wave of motivation.';
      phaseColor = AppColors.getFollicularPhaseColor(context);
    } else if (currentCycleDay <= 15) {
      phaseTitle = 'Ovulation';
      phaseDescription = 'You\'re at your peak! Confidence is high, energy is electric. Perfect time for important conversations, social connections, and pushing your limits.';
      phaseColor = AppColors.getOvulationDayColor(context);
    } else {
      phaseTitle = 'Luteal Phase';
      phaseDescription = 'Time to turn inward. Your body is asking for gentler rhythms. Listen to yourself, rest when needed, and embrace cozy self-care.';
      phaseColor = AppColors.getLutealPhaseColor(context);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: phaseColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                phaseTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: phaseColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: phaseColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Day $currentCycleDay of $_averageCycleLength',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: phaseColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              phaseDescription,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    '💡 Tips for this phase:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (currentCycleDay <= 5)
                    Text(
                      '• Hydrate like you mean it 💧\n• Heat, gentle movement, and rest are your friends\n• This is your permission to slow down',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onPrimaryContainer,
                        height: 1.5,
                      ),
                    )
                  else if (currentCycleDay <= 13)
                    Text(
                      '• Say yes to that new challenge 💪\n• Push yourself - your body can handle it\n• Schedule fun plans with friends',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onPrimaryContainer,
                        height: 1.5,
                      ),
                    )
                  else if (currentCycleDay <= 15)
                    Text(
                      '• Own your power - you\'ve got this! ✨\n• Perfect moment for big conversations\n• Channel this energy into what matters',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onPrimaryContainer,
                        height: 1.5,
                      ),
                    )
                  else
                    Text(
                      '• Give yourself permission to rest 🌙\n• Comfort foods and cozy vibes\n• Say no to unnecessary stress',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onPrimaryContainer,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Thanks!',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogPeriodDialog extends StatefulWidget {
  final DateTime initialDate;

  const _LogPeriodDialog({required this.initialDate});

  @override
  State<_LogPeriodDialog> createState() => _LogPeriodDialogState();
}

class _LogPeriodDialogState extends State<_LogPeriodDialog> {
  late DateTime selectedDate;
  FlowIntensity? selectedIntensity;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Log Period'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When did your period start?',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 90)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Flow intensity:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFlowButton(
                  FlowIntensity.light,
                  'Light',
                  Icons.water_drop_outlined,
                  colorScheme,
                ),
                _buildFlowButton(
                  FlowIntensity.medium,
                  'Medium',
                  Icons.water_drop,
                  colorScheme,
                ),
                _buildFlowButton(
                  FlowIntensity.heavy,
                  'Heavy',
                  Icons.water_drop,
                  colorScheme,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: selectedIntensity != null
              ? () {
                  Navigator.pop(context, {
                    'date': selectedDate,
                    'intensity': selectedIntensity,
                  });
                }
              : null,
          child: const Text('Log Period'),
        ),
      ],
    );
  }

  Widget _buildFlowButton(
    FlowIntensity intensity,
    String label,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    final isSelected = selectedIntensity == intensity;
    
    return InkWell(
      onTap: () => setState(() => selectedIntensity = intensity),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 85,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.errorContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.error
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.error : colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.onErrorContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
