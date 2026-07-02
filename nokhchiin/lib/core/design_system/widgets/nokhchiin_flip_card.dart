import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_system.dart';

/// 3D flip-карточка из Figma (только презентация).
class NokhchiinFlipCard extends StatelessWidget {
  const NokhchiinFlipCard({
    super.key,
    required this.flipped,
    required this.front,
    required this.back,
    this.onTap,
    this.radius = 26,
  });

  final bool flipped;
  final Widget front;
  final Widget back;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: IosMotion.curveGentle,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final rotate = Tween(begin: math.pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) {
              final isUnder = child!.key != ValueKey(flipped);
              final value = isUnder ? math.min(rotate.value, math.pi / 2) : rotate.value;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(value),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: flipped
            ? KeyedSubtree(key: const ValueKey(true), child: back)
            : KeyedSubtree(key: const ValueKey(false), child: front),
      ),
    );
  }
}

/// Обёртка лицевой стороны карточки.
class NokhchiinFlashcardFace extends StatelessWidget {
  const NokhchiinFlashcardFace({
    super.key,
    required this.child,
    this.accent = false,
    this.radius = 26,
  });

  final Widget child;
  final bool accent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: accent ? tokens.accent : tokens.surface,
        borderRadius: BorderRadius.circular(radius),
        border: accent ? null : Border.all(color: tokens.separator, width: 1.5),
      ),
      child: child,
    );
  }
}
