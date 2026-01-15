import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/profile_service.dart';
import '../../services/cycle_analyzer.dart';
import '../../constants/app_colors.dart';
import '../../core/feedback/feedback_service.dart';

/// Settings screen where users can adjust cycle information
/// Allows editing cycle length, period length, and viewing prediction accuracy
class CycleSettingsScreen extends ConsumerStatefulWidget {
  const CycleSettingsScreen({super.key});

  @override
  ConsumerState<CycleSettingsScreen> createState() =>
      _CycleSettingsScreenState();
}

class _CycleSettingsScreenState extends ConsumerState<CycleSettingsScreen> {
  final _supabase = ProfileService();
  bool _isLoading = true;
  bool _isSaving = false;

  // Cycle settings
  int _cycleLength = 28;
  int _periodLength = 5;
  DateTime? _lastPeriodStart;
  double _predictionConfidence = 0.0;
  String _predictionMethod = 'static';

  // Prediction stats
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final userData = await _supabase.getUserData();
      
      if (userData == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userId = _supabase.currentUser?.id;

      if (userId != null) {
        final stats = await CycleAnalyzer.getPredictionStats(userId);
        setState(() {
          _stats = stats;
        });
      }

      setState(() {
        _cycleLength = userData['cycle_length'] as int? ?? 28;
        _periodLength = userData['period_length'] as int? ?? 5;
        _lastPeriodStart = userData['last_period_start'] != null
            ? DateTime.parse(userData['last_period_start']!)
            : null;
        _predictionConfidence =
            userData['prediction_confidence'] as double? ?? 0.0;
        _predictionMethod = userData['prediction_method'] as String? ?? 'static';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await _supabase.updateUserData({
        'cycle_length': _cycleLength,
        'period_length': _periodLength,
        if (_lastPeriodStart != null)
          'last_period_start': _lastPeriodStart!.toIso8601String(),
      });

      // Recalculate predictions with new settings
      final userId = _supabase.currentUser?.id;
      if (userId != null) {
        await CycleAnalyzer.recalculateAfterPeriodStart(userId);
      }

      if (mounted) {
        FeedbackService.showSuccess(
          context,
          'Cycle settings updated. Your predictions will reflect these changes.',
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, e);
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cycle Settings'),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPredictionAccuracyCard(),
                  const SizedBox(height: 24),
                  _buildCycleLengthSection(),
                  const SizedBox(height: 24),
                  _buildPeriodLengthSection(),
                  const SizedBox(height: 24),
                  _buildLastPeriodSection(),
                  const SizedBox(height: 24),
                  _buildInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildPredictionAccuracyCard() {
    final totalPredictions = _stats['total_predictions'] as int? ?? 0;
    final avgError = _stats['average_error'] as double? ?? 0.0;
    final accuracyPercent = _stats['accuracy_within_2_days'] as double? ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Prediction Accuracy',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (totalPredictions == 0)
              Text(
                'Not enough data yet. Track at least 2 cycles to see your personalized accuracy',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.getTextSecondaryColor(context),
                    ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Confidence:',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '${(_predictionConfidence * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _getConfidenceColor(_predictionConfidence, context),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _predictionConfidence,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  _getConfidenceColor(_predictionConfidence, context),
                ),
              ),
              const SizedBox(height: 16),
              _buildStatRow('Total Predictions:', '$totalPredictions'),
              _buildStatRow('Average Error:', '±${avgError.toStringAsFixed(1)} days'),
              _buildStatRow('Accuracy (±2 days):', '${accuracyPercent.toStringAsFixed(0)}%'),
              _buildStatRow('Method:', _predictionMethod.replaceAll('_', ' ')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCycleLengthSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Cycle Length',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Days from period start to next period start',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.getTextSecondaryColor(context)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _cycleLength > 21
                      ? () => setState(() => _cycleLength--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_cycleLength days',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                IconButton(
                  onPressed: _cycleLength < 45
                      ? () => setState(() => _cycleLength++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            Slider(
              value: _cycleLength.toDouble(),
              min: 21,
              max: 45,
              divisions: 24,
              label: '$_cycleLength days',
              onChanged: (value) => setState(() => _cycleLength = value.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodLengthSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Period Length',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Number of days you typically bleed',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.getTextSecondaryColor(context)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _periodLength > 2
                      ? () => setState(() => _periodLength--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_periodLength days',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                IconButton(
                  onPressed: _periodLength < 10
                      ? () => setState(() => _periodLength++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            Slider(
              value: _periodLength.toDouble(),
              min: 2,
              max: 10,
              divisions: 8,
              label: '$_periodLength days',
              onChanged: (value) => setState(() => _periodLength = value.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastPeriodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Period Start Date',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Update this if you made a mistake during onboarding',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.getTextSecondaryColor(context)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _lastPeriodStart != null
                    ? DateFormat('MMMM d, yyyy').format(_lastPeriodStart!)
                    : 'Not set',
              ),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _lastPeriodStart ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 180)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _lastPeriodStart = picked);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How Predictions Work',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• We learn from your actual cycles over time\n'
            '• Predictions get smarter after 2-3 cycles\n'
            '• Regular cycles = more confident predictions\n'
            '• Your manual adjustments help us improve',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Returns WCAG AA compliant color based on confidence level
  Color _getConfidenceColor(double confidence, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (confidence > 0.8) {
      return isDark ? Colors.green.shade400 : Colors.green.shade700;
    } else if (confidence > 0.6) {
      return isDark ? Colors.orange.shade400 : Colors.orange.shade700;
    } else {
      return isDark ? Colors.red.shade400 : Colors.red.shade700;
    }
  }
}
