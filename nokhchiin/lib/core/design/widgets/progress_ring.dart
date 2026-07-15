import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../tokens/nokhchiin_colors.dart';

/// Кольцо прогресса (mastery, цели дня).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 88,
    this.strokeWidth = 8,
    this.label,
    this.center,
  });

  final int percent;
  final double size;
  final double strokeWidth;
  final String? label;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final p = (percent / 100).clamp(0.0, 1.0);
    final color = p >= 0.8
        ? NokhchiinColors.masteryHigh
        : p >= 0.4
        ? NokhchiinColors.masteryMid
        : NokhchiinColors.masteryLow;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: p,
              strokeWidth: strokeWidth,
              color: color,
              trackColor: color.withValues(alpha: 0.2),
            ),
          ),
          center ??
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (label != null)
                    Text(label!, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, fill);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
