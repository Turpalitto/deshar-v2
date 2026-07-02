import 'package:flutter/material.dart';
import '../design_system.dart';

/// Сегментированный прогресс-бар урока из Figma (ProgBar).
class NokhchiinSegmentProgress extends StatelessWidget {
  const NokhchiinSegmentProgress({
    super.key,
    required this.step,
    this.total = 5,
    this.color,
    this.trackColor,
    this.height = 4,
    this.gap = 4,
  });

  final int step;
  final int total;
  final Color? color;
  final Color? trackColor;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final active = color ?? tokens.accent;
    final track = trackColor ?? tokens.surfaceMuted;

    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < total - 1 ? gap : 0),
            child: AnimatedContainer(
              duration: IosMotion.interact,
              curve: IosMotion.curveSnappy,
              height: height,
              decoration: BoxDecoration(
                color: i < step ? active : track,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        );
      }),
    );
  }
}
