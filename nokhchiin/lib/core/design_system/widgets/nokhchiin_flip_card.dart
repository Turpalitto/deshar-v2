import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_system.dart';

/// 3D flip-карточка из Figma (только презентация).
class NokhchiinFlipCard extends StatefulWidget {
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
  State<NokhchiinFlipCard> createState() => _NokhchiinFlipCardState();
}

class _NokhchiinFlipCardState extends State<NokhchiinFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animation = CurvedAnimation(parent: _controller, curve: IosMotion.curveGentle);
    if (widget.flipped) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant NokhchiinFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flipped != widget.flipped) {
      if (widget.flipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                final angle = _animation.value * math.pi;
                final showFront = angle < math.pi / 2;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: showFront
                      ? widget.front
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child: widget.back,
                        ),
                );
              },
            ),
          ),
        );
      },
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

    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: accent ? tokens.accent : tokens.surface,
          borderRadius: BorderRadius.circular(radius),
          border: accent ? null : Border.all(color: tokens.separator, width: 1.5),
        ),
        child: child,
      ),
    );
  }
}
