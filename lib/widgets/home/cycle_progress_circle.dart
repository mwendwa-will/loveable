import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lovely/constants/app_colors.dart';

class CycleProgressCircle extends StatelessWidget {
  final int currentCycleDay;
  final int totalCycleDays;
  final int averagePeriodLength;
  final bool isPeriod;

  const CycleProgressCircle({
    super.key,
    required this.currentCycleDay,
    required this.totalCycleDays,
    required this.averagePeriodLength,
    required this.isPeriod,
  });

  @override
  Widget build(BuildContext context) {
    // Phase calculation logic
    final ovulationDay = totalCycleDays - 14;
    final fertileStart = ovulationDay - 5;
    final fertileEnd = ovulationDay;

    return Center(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: CustomPaint(
          size: const Size(300, 300),
          painter: _CycleSegmentPainter(
            currentDay: currentCycleDay,
            totalDays: totalCycleDays,
            periodDays: averagePeriodLength,
            fertileStart: fertileStart,
            fertileEnd: fertileEnd,
            ovulationDay: ovulationDay,
            isPeriod: isPeriod,
            menstrualColor: AppColors.getMenstrualPhaseColor(context),
            follicularColor: AppColors.getFollicularPhaseColor(context),
            ovulationColor: AppColors.getOvulationDayColor(context),
            lutealColor: AppColors.getLutealPhaseColor(context),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _CycleSegmentPainter extends CustomPainter {
  final int currentDay;
  final int totalDays;
  final int periodDays;
  final int fertileStart;
  final int fertileEnd;
  final int ovulationDay;
  final bool isPeriod;

  final Color menstrualColor;
  final Color follicularColor;
  final Color ovulationColor;
  final Color lutealColor;
  final Color backgroundColor;
  final Color indicatorColor;

  _CycleSegmentPainter({
    required this.currentDay,
    required this.totalDays,
    required this.periodDays,
    required this.fertileStart,
    required this.fertileEnd,
    required this.ovulationDay,
    required this.isPeriod,
    required this.menstrualColor,
    required this.follicularColor,
    required this.ovulationColor,
    required this.lutealColor,
    required this.backgroundColor,
    required this.indicatorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 15;
    const strokeWidth = 14.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final Paint bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 1. Draw Background Ring
    canvas.drawArc(rect, 0, 2 * math.pi, false, bgPaint);

    final double dayAngle = (2 * math.pi) / totalDays;
    const double gapAngle = 0.04; // Small gap between segments
    const double startAngleOffset = -math.pi / 2;

    // Phase: Menstrual
    _drawSegment(
      canvas,
      rect,
      startAngleOffset + (gapAngle / 2),
      (periodDays * dayAngle) - gapAngle,
      menstrualColor,
      strokeWidth,
    );

    // Phase: Follicular (until fertile window)
    double follicularStart = periodDays * dayAngle;
    double follicularSweep = (fertileStart - periodDays) * dayAngle;
    _drawSegment(
      canvas,
      rect,
      startAngleOffset + follicularStart + (gapAngle / 2),
      follicularSweep - gapAngle,
      follicularColor.withValues(alpha: 0.4),
      strokeWidth,
    );

    // Phase: Fertile Window
    double fertileStartAngle = fertileStart * dayAngle;
    double fertileSweep = (fertileEnd - fertileStart) * dayAngle;
    _drawSegment(
      canvas,
      rect,
      startAngleOffset + fertileStartAngle + (gapAngle / 2),
      fertileSweep - gapAngle,
      follicularColor, // Higher opacity teal
      strokeWidth,
    );

    // Phase: Ovulation Day (Represented as a point or very small segment)
    double ovulationStartAngle = ovulationDay * dayAngle;
    _drawSegment(
      canvas,
      rect,
      startAngleOffset + ovulationStartAngle,
      dayAngle,
      ovulationColor,
      strokeWidth + 2, // Slightly thicker
    );

    // Phase: Luteal
    double lutealStart = (ovulationDay + 1) * dayAngle;
    double lutealSweep = (totalDays - (ovulationDay + 1)) * dayAngle;
    _drawSegment(
      canvas,
      rect,
      startAngleOffset + lutealStart + (gapAngle / 2),
      lutealSweep - gapAngle,
      lutealColor,
      strokeWidth,
    );

    // Today Indicator
    final double todayAngle = ((currentDay - 1) * dayAngle) + startAngleOffset;
    final indicatorPos = Offset(
      center.dx + radius * math.cos(todayAngle),
      center.dy + radius * math.sin(todayAngle),
    );

    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(indicatorPos, 10, shadowPaint);
    canvas.drawCircle(indicatorPos, 8, indicatorPaint);
    canvas.drawCircle(indicatorPos, 5, Paint()..color = indicatorColor);
  }

  void _drawSegment(
    Canvas canvas,
    Rect rect,
    double start,
    double sweep,
    Color color,
    double width,
  ) {
    if (sweep <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
