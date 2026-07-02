import 'package:flutter/material.dart';

/// Иконка приложения из Figma Make — терракота, горы, «Н».
class NokhchiinAppIcon extends StatelessWidget {
  const NokhchiinAppIcon({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _NokhchiinAppIconPainter()),
    );
  }
}

class _NokhchiinAppIconPainter extends CustomPainter {
  static const _terra = Color(0xFFC4724E);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.scale(scale);

    final bg = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 100, 100),
      const Radius.circular(22),
    );
    canvas.drawRRect(bg, Paint()..color = _terra);

    final mountain1 = Path()
      ..moveTo(12, 72)
      ..lineTo(35, 38)
      ..lineTo(50, 52)
      ..lineTo(65, 32)
      ..lineTo(88, 72)
      ..close();
    canvas.drawPath(mountain1, Paint()..color = const Color(0x26FFFFFF));

    final mountain2 = Path()
      ..moveTo(22, 72)
      ..lineTo(42, 44)
      ..lineTo(50, 52)
      ..lineTo(58, 40)
      ..lineTo(78, 72)
      ..close();
    canvas.drawPath(mountain2, Paint()..color = const Color(0x1FFFFFFF));

    final palochka = RRect.fromRectAndRadius(
      const Rect.fromLTWH(47, 13, 3, 14),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(palochka, Paint()..color = const Color(0x80FFFFFF));

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Н',
        style: TextStyle(
          color: Colors.white,
          fontSize: 52,
          fontWeight: FontWeight.w700,
          letterSpacing: -2,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(50 - 52 / 2, 74 - 52));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
