import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lovely/services/tip_service.dart';

class DailyTipCard extends ConsumerWidget {
  final int? cycleDay;
  final int? avgCycleLength;
  final bool? isPeriod;

  const DailyTipCard({
    super.key,
    this.cycleDay,
    this.avgCycleLength,
    this.isPeriod,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tip = TipService().getTipForCycleDay(
      cycleDay ?? 1,
      avgCycleLength ?? 28,
      isPeriod ?? false,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.teal.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Daily Tip',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tip,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: Colors.teal.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
