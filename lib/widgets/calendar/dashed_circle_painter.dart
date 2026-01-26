import 'dart:math';
import 'package:flutter/material.dart';

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashes;
  final double gapSize;

  DashedCirclePainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashes = 20,
    this.gapSize = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    // We draw dashes using arc segments
    const double totalAngle = 2 * pi;
    final double dashAngle =
        (totalAngle / dashes) * 0.6; // Dash is 60% of segment

    for (int i = 0; i < dashes; i++) {
      final startAngle = (i * totalAngle / dashes) - pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashes != dashes ||
        oldDelegate.gapSize != gapSize;
  }
}
