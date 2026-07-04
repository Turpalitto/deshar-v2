import 'package:flutter/material.dart';
import '../design/tokens/nokhchiin_colors.dart';

/// Мягкие Disney-подобные иллюстрации без стоковых иконок — CustomPainter + градиенты.
class WordIllustration extends StatelessWidget {
  const WordIllustration({
    super.key,
    required this.category,
    this.emoji,
    this.size = 120,
  });

  final String? category;
  final String? emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = _palette(category);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SoftScenePainter(
          colors: colors,
          emoji: emoji,
        ),
      ),
    );
  }

  static List<Color> _palette(String? cat) => switch (cat) {
        'animals' => [const Color(0xFFFFE0B2), const Color(0xFFFFCC80)],
        'family' => [const Color(0xFFF8BBD9), const Color(0xFFF48FB1)],
        'food' => [const Color(0xFFC8E6C9), const Color(0xFFA5D6A7)],
        'nature' => [const Color(0xFFB3E5FC), const Color(0xFF81D4FA)],
        'greetings' => [const Color(0xFFE1BEE7), const Color(0xFFCE93D8)],
        'verbs' => [const Color(0xFFFFF9C4), const Color(0xFFFFF176)],
        _ => [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
      };
}

class _SoftScenePainter extends CustomPainter {
  _SoftScenePainter({required this.colors, this.emoji});
  final List<Color> colors;
  final String? emoji;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.22)),
      bg,
    );

    // Мягкое «солнце»
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.22),
      size.width * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    // Холм
    final hill = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.55, size.width, size.height * 0.85)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, Paint()..color = Colors.white.withValues(alpha: 0.35));

    if (emoji != null && emoji!.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(text: emoji, style: TextStyle(fontSize: size.width * 0.42)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset((size.width - tp.width) / 2, size.height * 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoftScenePainter old) =>
      old.emoji != emoji || old.colors != colors;
}

/// Персонаж-гид Цхьогал (лисичка) — добрый Disney-стиль
class FoxMascot extends StatelessWidget {
  const FoxMascot({super.key, this.size = 80, this.emotion = FoxEmotion.happy});
  final double size;
  final FoxEmotion emotion;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FoxPainter(emotion: emotion)),
    );
  }
}

enum FoxEmotion { happy, thinking, celebrate }

class _FoxPainter extends CustomPainter {
  _FoxPainter({required this.emotion});
  final FoxEmotion emotion;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final orange = const Color(0xFFFF8A50);
    final cream = const Color(0xFFFFF3E0);

    // Ears
    for (final dx in [-0.22, 0.22]) {
      final ear = Path()
        ..moveTo(cx + size.width * dx, cy - size.height * 0.1)
        ..lineTo(cx + size.width * (dx - 0.08), cy - size.height * 0.42)
        ..lineTo(cx + size.width * (dx + 0.08), cy - size.height * 0.1)
        ..close();
      canvas.drawPath(ear, Paint()..color = orange);
    }

    // Head
    canvas.drawCircle(Offset(cx, cy), size.width * 0.38, Paint()..color = orange);
    // Muzzle
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + size.height * 0.08), width: size.width * 0.35, height: size.height * 0.22),
      Paint()..color = cream,
    );

    // Eyes — большие Disney-глаза
    for (final dx in [-0.12, 0.12]) {
      canvas.drawCircle(Offset(cx + size.width * dx, cy - size.height * 0.04), size.width * 0.07, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(cx + size.width * dx, cy - size.height * 0.02), size.width * 0.04, Paint()..color = const Color(0xFF3E2723));
    }

    // Nose
    canvas.drawCircle(Offset(cx, cy + size.height * 0.06), size.width * 0.04, Paint()..color = const Color(0xFF3E2723));

    if (emotion == FoxEmotion.celebrate) {
      canvas.drawCircle(Offset(cx - size.width * 0.35, cy - size.height * 0.35), 4, Paint()..color = NokhchiinColors.warning);
      canvas.drawCircle(Offset(cx + size.width * 0.38, cy - size.height * 0.3), 3, Paint()..color = NokhchiinColors.meadow);
    }
  }

  @override
  bool shouldRepaint(covariant _FoxPainter old) => old.emotion != emotion;
}
