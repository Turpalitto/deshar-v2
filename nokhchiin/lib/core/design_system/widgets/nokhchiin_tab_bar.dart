import 'package:flutter/material.dart';
import '../design_system.dart';

/// iOS tab bar из Figma — Главная · Миры · Повтор · Профиль.
class NokhchiinTabBar extends StatelessWidget {
  const NokhchiinTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.accent,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? accent;

  static const _labels = ['Главная', 'Миры', 'Повтор', 'Профиль'];

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final active = accent ?? tokens.accent;

    return Container(
      decoration: BoxDecoration(
        color: tokens.backgroundElevated,
        border: Border(top: BorderSide(color: tokens.separator)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = currentIndex == i;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TabIcon(index: i, color: isActive ? active : tokens.textTertiary),
                  const SizedBox(height: 2),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: isActive ? active : tokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _TabIconPainter(index: index, color: color),
    );
  }
}

class _TabIconPainter extends CustomPainter {
  _TabIconPainter({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final s = size.width / 24;

    switch (index) {
      case 0:
        final path = Path()
          ..moveTo(3 * s, 10.5 * s)
          ..lineTo(12 * s, 3 * s)
          ..lineTo(21 * s, 10.5 * s)
          ..lineTo(21 * s, 20 * s)
          ..lineTo(16 * s, 20 * s)
          ..lineTo(16 * s, 15 * s)
          ..lineTo(8 * s, 15 * s)
          ..lineTo(8 * s, 20 * s)
          ..lineTo(3 * s, 20 * s)
          ..close();
        canvas.drawPath(path, paint);
      case 1:
        canvas.drawCircle(Offset(12 * s, 12 * s), 10 * s, paint);
        canvas.drawLine(Offset(2 * s, 12 * s), Offset(22 * s, 12 * s), paint);
        final globe = Path()
          ..moveTo(12 * s, 2 * s)
          ..cubicTo(9.5 * s, 5 * s, 8 * s, 8.3 * s, 8 * s, 12 * s)
          ..cubicTo(8 * s, 15.7 * s, 9.5 * s, 19 * s, 12 * s, 22 * s)
          ..cubicTo(14.5 * s, 19 * s, 16 * s, 15.7 * s, 16 * s, 12 * s)
          ..cubicTo(16 * s, 8.3 * s, 14.5 * s, 5 * s, 12 * s, 2 * s);
        canvas.drawPath(globe, paint);
      case 2:
        canvas.drawLine(Offset(4 * s, 7 * s), Offset(14 * s, 7 * s), paint);
        final arc = Path()
          ..moveTo(14 * s, 7 * s)
          ..cubicTo(20 * s, 7 * s, 20 * s, 19 * s, 14 * s, 19 * s)
          ..lineTo(4 * s, 19 * s);
        canvas.drawPath(arc, paint);
        canvas.drawLine(Offset(7 * s, 4 * s), Offset(4 * s, 7 * s), paint);
        canvas.drawLine(Offset(7 * s, 4 * s), Offset(10 * s, 7 * s), paint);
      case 3:
        canvas.drawCircle(Offset(12 * s, 8 * s), 4 * s, paint);
        final body = Path()
          ..moveTo(4 * s, 20 * s)
          ..cubicTo(4 * s, 16.7 * s, 7.6 * s, 14 * s, 12 * s, 14 * s)
          ..cubicTo(16.4 * s, 14 * s, 20 * s, 16.7 * s, 20 * s, 20 * s);
        canvas.drawPath(body, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TabIconPainter oldDelegate) {
    return oldDelegate.index != index || oldDelegate.color != color;
  }
}
