import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lunara/navigation/app_router.dart';

// Note: We'll likely need to pass callbacks or use a provider for saving data
// For now, this extracts the UI of the bottom sheet

class QuickLogMenu extends StatelessWidget {
  final DateTime selectedDate;

  const QuickLogMenu({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Log',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickAddButton(
                context,
                icon: Icons.water_drop,
                label: 'Period',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.dailyLog,
                    arguments: {'selectedDate': selectedDate},
                  );
                },
              ),
              _buildQuickAddButton(
                context,
                icon: Icons.mood,
                label: 'Mood',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to mood log or show dialog
                  // Ideally logic handled by parent or router
                  // For now simple push
                },
              ),
              _buildQuickAddButton(
                context,
                icon: Icons.healing,
                label: 'Symptom',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildQuickAddButton(
                context,
                icon: Icons.note_alt,
                label: 'Note',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
