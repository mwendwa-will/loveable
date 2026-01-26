import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lovely/models/period.dart';
import 'package:lovely/services/period_service.dart';
import 'package:lovely/constants/app_colors.dart';

class CycleHistoryScreen extends ConsumerWidget {
  const CycleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We use a FutureBuilder or a dedicated provider.
    // Given the current architecture, let's use a FutureBuilder for simplicity or a simple provider.
    final periodService = ref.watch(periodServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cycle History',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Period>>(
        future: periodService.getCompletedPeriods(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final periods = snapshot.data ?? [];

          if (periods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No completed cycles yet',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: periods.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final period = periods[index];
              return _CycleHistoryCard(period: period);
            },
          );
        },
      ),
    );
  }
}

class _CycleHistoryCard extends StatelessWidget {
  final Period period;

  const _CycleHistoryCard({required this.period});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final duration = period.endDate != null
        ? period.endDate!.difference(period.startDate).inDays + 1
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${dateFormat.format(period.startDate)} - ${period.endDate != null ? dateFormat.format(period.endDate!) : "Ongoing"}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (duration != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getMenstrualPhaseColor(
                      context,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$duration days',
                    style: GoogleFonts.inter(
                      color: AppColors.getMenstrualPhaseColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Flow: ${period.flowIntensity?.name.toUpperCase() ?? "UNKNOWN"}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
