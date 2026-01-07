import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/cycle_analyzer.dart';
import '../constants/app_colors.dart';
import '../providers/period_provider.dart';

/// Widget that displays next period prediction with confidence
/// Uses CycleAnalyzer with floating window approach for accurate predictions
/// Shows both current prediction and baseline for context
class PredictionCard extends ConsumerWidget {
  const PredictionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, Set<DateTime>>>(
      future: CycleAnalyzer.getCurrentPrediction(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final predictions = snapshot.data!;
        final predictedPeriodDays = predictions['predictedPeriodDays'] ?? <DateTime>{};
        
        // Find next predicted period (first date after today)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        final futurePeriods = predictedPeriodDays
            .where((date) => date.isAfter(today) || date.isAtSameMomentAs(today))
            .toList()
          ..sort();
        
        if (futurePeriods.isEmpty) return const SizedBox.shrink();
        final nextPredicted = futurePeriods.first;
        
        // Get user data for baseline comparison
        final userDataAsync = ref.watch(userDataProvider);

        return userDataAsync.when(
          data: (userData) {
            final confidence = (userData?['prediction_confidence'] as num?)?.toDouble() ?? 0.75;
            final method = userData?['prediction_method'] as String? ?? 'floating_window';

            final daysUntil = nextPredicted.difference(now).inDays;
            final baselineNextPeriod = _calculateBaselinePrediction(userData);
            final baselineDifferent = baselineNextPeriod != null && 
                !DateUtils.isSameDay(baselineNextPeriod, nextPredicted);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.getPeriodColor(context).withValues(alpha: 0.15),
                      AppColors.getOvulationColor(context).withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.getPeriodColor(context)
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: AppColors.getPeriodColor(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next Period Prediction',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  _getMethodDescription(method),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.getTextSecondaryColor(context),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Main prediction text
                      Text(
                        _getPredictionText(daysUntil, confidence),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                            ),
                      ),
                      const SizedBox(height: 8),

                      // Date
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 16,
                            color: AppColors.getTextSecondaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('EEEE, MMMM d').format(nextPredicted),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),

                      // Baseline comparison if different
                      if (baselineDifferent) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Baseline prediction (for reference):',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, MMMM d').format(baselineNextPeriod),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Confidence indicator
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Confidence',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.getTextSecondaryColor(context),
                                          ),
                                    ),
                                    Text(
                                      '${(confidence * 100).toStringAsFixed(0)}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: _getConfidenceColor(confidence, context),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: confidence,
                                    minHeight: 6,
                                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation(
                                      _getConfidenceColor(confidence, context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Info tooltip
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getConfidenceTip(confidence),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 12,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
    );
  }

  DateTime? _calculateBaselinePrediction(Map<String, dynamic>? userData) {
    if (userData == null) return null;

    final lastPeriodStart = userData['last_period_start'];
    if (lastPeriodStart == null) return null;

    try {
      final baseline = (userData['baseline_cycle_length'] as num?)?.toDouble() ?? 28.0;
      final lastStart = DateTime.parse(lastPeriodStart as String);
      return lastStart.add(Duration(days: baseline.toInt()));
    } catch (e) {
      return null;
    }
  }

  String _getPredictionText(int daysUntil, double confidence) {
    if (daysUntil <= 0) return 'Your period may have started';
    if (daysUntil == 1) return 'Your period may start tomorrow';

    // Adjust language based on confidence
    if (confidence >= 0.85) {
      return 'Your period will likely start in $daysUntil days';
    } else if (confidence >= 0.65) {
      return 'Your period is expected in about $daysUntil days';
    } else {
      return 'Your period may start around $daysUntil days from now';
    }
  }

  Color _getConfidenceColor(double confidence, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (confidence >= 0.85) {
      // High confidence - green with WCAG AA contrast
      return isDark ? Colors.green.shade400 : Colors.green.shade700;
    } else if (confidence >= 0.65) {
      // Medium confidence - orange with WCAG AA contrast
      return isDark ? Colors.orange.shade400 : Colors.orange.shade700;
    } else {
      // Low confidence - red with WCAG AA contrast  
      return isDark ? Colors.red.shade400 : Colors.red.shade700;
    }
  }

  String _getConfidenceTip(double confidence) {
    if (confidence >= 0.85) {
      return 'High confidence - pattern well established';
    } else if (confidence >= 0.65) {
      return 'Moderate confidence - track more cycles for accuracy';
    } else {
      return 'Low confidence - prediction will improve over time';
    }
  }

  String _getMethodDescription(String method) {
    if (method == 'floating_window') {
      return 'Based on recent cycles (adapts to changes)';
    } else if (method == 'simple_average') {
      return 'Based on your tracked cycles';
    } else {
      return 'Based on your reported cycle length';
    }
  }
}
