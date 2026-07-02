import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_system.dart';

/// Кольцо прогресса из Figma Make (Arc).
class NokhchiinArcProgress extends StatelessWidget {
  const NokhchiinArcProgress({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 6,
    this.color,
    this.trackColor,
    this.label,
    this.center,
  });

  /// 0.0 … 1.0
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final String? label;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final active = color ?? tokens.accent;
    final track = trackColor ?? tokens.accentMuted;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ArcPainter(
              progress: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              activeColor: active,
              trackColor: track,
            ),
          ),
          if (center != null)
            center!
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: size > 90 ? 20 : 11,
                    fontWeight: FontWeight.w700,
                    color: color ?? tokens.accent,
                  ),
                ),
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(fontSize: 11, color: tokens.textTertiary),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.activeColor,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color activeColor;
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

    final fill = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
