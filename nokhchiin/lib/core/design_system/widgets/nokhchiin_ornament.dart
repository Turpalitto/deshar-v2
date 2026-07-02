import 'package:flutter/material.dart';

/// Вайнахский ромбовый орнамент из Figma Make.
class NokhchiinOrnament extends StatelessWidget {
  const NokhchiinOrnament({
    super.key,
    this.opacity = 0.05,
    this.light = false,
  });

  final double opacity;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          painter: _WainakhOrnamentPainter(light: light),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _WainakhOrnamentPainter extends CustomPainter {
  _WainakhOrnamentPainter({required this.light});

  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = light ? const Color(0xFFE8D5C4) : const Color(0xFF3D2E1C);
    final paintOuter = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final paintInner = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final paintLine = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4;

    const cellW = 46.0;
    const cellH = 62.0;
    final cols = (size.width / cellW).ceil() + 2;
    final rows = (size.height / cellH).ceil() + 2;

    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < rows; j++) {
        final x = i * cellW - 6;
        final y = j * cellH - 4;
        _drawDiamond(canvas, Offset(x, y), paintOuter, paintInner, paintLine);
      }
    }
  }

  void _drawDiamond(
    Canvas canvas,
    Offset origin,
    Paint outer,
    Paint inner,
    Paint line,
  ) {
    const cx = 23.0;
    const cy = 10.0;

    final outerPath = Path()
      ..moveTo(origin.dx + cx, origin.dy)
      ..lineTo(origin.dx + cx + 10, origin.dy + cy)
      ..lineTo(origin.dx + cx, origin.dy + 20)
      ..lineTo(origin.dx + cx - 10, origin.dy + cy)
      ..close();
    canvas.drawPath(outerPath, outer);

    final innerPath = Path()
      ..moveTo(origin.dx + cx, origin.dy + 4)
      ..lineTo(origin.dx + cx + 6, origin.dy + cy)
      ..lineTo(origin.dx + cx, origin.dy + 16)
      ..lineTo(origin.dx + cx - 6, origin.dy + cy)
      ..close();
    canvas.drawPath(innerPath, inner);

    canvas.drawLine(
      Offset(origin.dx + cx, origin.dy),
      Offset(origin.dx + cx, origin.dy + 20),
      line,
    );
    canvas.drawLine(
      Offset(origin.dx + cx - 10, origin.dy + cy),
      Offset(origin.dx + cx + 10, origin.dy + cy),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _WainakhOrnamentPainter oldDelegate) {
    return oldDelegate.light != light;
  }
}
