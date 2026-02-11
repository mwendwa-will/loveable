import 'package:flutter/material.dart';
import 'package:lunara/services/profile_service.dart';
import 'package:intl/intl.dart';
import 'package:lunara/core/feedback/feedback_service.dart';

class PregnancyModeScreen extends StatefulWidget {
  const PregnancyModeScreen({super.key});

  @override
  State<PregnancyModeScreen> createState() => _PregnancyModeScreenState();
}

class _PregnancyModeScreenState extends State<PregnancyModeScreen> {
  final _profileService = ProfileService();
  bool _isLoading = true;
  bool _pregnancyModeEnabled = false;
  DateTime? _conceptionDate;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _loadPregnancyInfo();
  }

  Future<void> _loadPregnancyInfo() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _profileService.getUserData();
      final pregnancyInfo = await _profileService.getPregnancyInfo();

      setState(() {
        _pregnancyModeEnabled = userData?['pregnancy_mode'] == true;
        _conceptionDate = pregnancyInfo?['conception_date'];
        _dueDate = pregnancyInfo?['due_date'];
      });
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, e);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enablePregnancyMode() async {
    final conceptionDate = await _showDatePicker(
      context,
      title: 'Select Conception Date',
      initialDate: DateTime.now().subtract(const Duration(days: 14)),
      lastDate: DateTime.now(),
    );

    if (conceptionDate == null) return;

    // Calculate due date (280 days from conception, or 40 weeks)
    final dueDate = conceptionDate.add(const Duration(days: 280));

    try {
      await _profileService.enablePregnancyMode(
        conceptionDate: conceptionDate,
        dueDate: dueDate,
      );

      if (mounted) {
        FeedbackService.showSuccess(
          context,
          'Pregnancy mode enabled!',
        );
      }

      await _loadPregnancyInfo();
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, e);
      }
    }
  }

  Future<void> _disablePregnancyMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Pregnancy Mode?'),
        content: const Text(
          'This will remove pregnancy tracking. Your other data will remain safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _profileService.disablePregnancyMode();

      if (mounted) {
        FeedbackService.showSuccess(
          context,
          'Pregnancy mode disabled',
        );
      }

      await _loadPregnancyInfo();
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, e);
      }
    }
  }

  Future<DateTime?> _showDatePicker(
    BuildContext context, {
    required String title,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
      helpText: title,
    );
  }

  int _getWeeksPregnant() {
    if (_conceptionDate == null) return 0;
    final daysSinceConception = DateTime.now()
        .difference(_conceptionDate!)
        .inDays;
    return (daysSinceConception / 7).floor();
  }

  int _getDaysUntilDue() {
    if (_dueDate == null) return 0;
    return _dueDate!.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pregnancy Mode')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pregnancy Mode'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_pregnancyModeEnabled) ...[
              const Icon(Icons.pregnant_woman, size: 120, color: Colors.pink),
              const SizedBox(height: 24),
              const Text(
                'Pregnancy Tracking',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enable pregnancy mode to track your pregnancy journey, monitor symptoms, and prepare for your baby\'s arrival.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _enablePregnancyMode,
                icon: const Icon(Icons.favorite),
                label: const Text('Enable Pregnancy Mode'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.baby_changing_station,
                        size: 80,
                        color: Colors.pink,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_getWeeksPregnant()} Weeks Pregnant',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_getDaysUntilDue()} days until due date',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.pink.shade900
                              : Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Conception Date',
                              _conceptionDate != null
                                  ? DateFormat(
                                      'MMM d, yyyy',
                                    ).format(_conceptionDate!)
                                  : 'N/A',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Due Date',
                              _dueDate != null
                                  ? DateFormat('MMM d, yyyy').format(_dueDate!)
                                  : 'N/A',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _disablePregnancyMode,
                icon: const Icon(Icons.close),
                label: const Text('Disable Pregnancy Mode'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
