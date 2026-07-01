import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';
import '../learning_path_visual_state.dart';

/// Сегмент тропы между двумя узлами.
class TrailSegmentVisual {
  const TrailSegmentVisual({required this.from, required this.to, required this.state});

  final Offset from;
  final Offset to;
  final PathNodeVisualState state;
}

/// Извилистая вертикальная тропа между узлами (CustomPainter).
class LearningPathTrailPainter extends CustomPainter {
  LearningPathTrailPainter({
    required this.segments,
    required this.tokens,
    required this.strokeWidth,
  });

  final List<TrailSegmentVisual> segments;
  final DesignTokens tokens;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    for (final segment in segments) {
      final path = _curveBetween(segment.from, segment.to);
      final completed = segment.state == PathNodeVisualState.completed;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = completed ? tokens.accent.withValues(alpha: 0.55) : tokens.separator;

      if (!completed) {
        paint.shader = null;
        _drawDashedPath(canvas, path, paint, dashLength: 10, gapLength: 8);
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  Path _curveBetween(Offset from, Offset to) {
    final path = Path()..moveTo(from.dx, from.dy);
    final midY = (from.dy + to.dy) / 2;
    final control1 = Offset(from.dx, midY);
    final control2 = Offset(to.dx, midY);
    path.cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, to.dx, to.dy);
    return path;
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, {required double dashLength, required double gapLength}) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        final extract = metric.extractPath(distance, next.clamp(0, metric.length));
        canvas.drawPath(extract, paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant LearningPathTrailPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.tokens != tokens ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Позиции узлов: вертикальная извилистая тропа (чередование сторон).
List<Offset> windingTrailNodePositions({
  required int count,
  required double width,
  required double topPadding,
  required double verticalSpacing,
  double horizontalAmplitude = 72,
}) {
  final centerX = width / 2;
  final positions = <Offset>[];
  for (var i = 0; i < count; i++) {
    final side = i.isEven ? -1.0 : 1.0;
    final wave = 0.75 + 0.25 * ((i % 3) / 2);
    final x = centerX + side * horizontalAmplitude * wave;
    final y = topPadding + i * verticalSpacing;
    positions.add(Offset(x, y));
  }
  return positions;
}
