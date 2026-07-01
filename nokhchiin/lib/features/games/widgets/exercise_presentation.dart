import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/design_system.dart';

/// Микро-анимация ответа: bounce (верно) / shake (неверно) + haptic.
class AnswerFeedbackAnimator extends StatefulWidget {
  const AnswerFeedbackAnimator({
    super.key,
    required this.child,
    required this.feedback,
  });

  /// `true` — верно, `false` — неверно, `null` — нейтрально.
  final bool? feedback;
  final Widget child;

  @override
  State<AnswerFeedbackAnimator> createState() => _AnswerFeedbackAnimatorState();
}

class _AnswerFeedbackAnimatorState extends State<AnswerFeedbackAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool? _lastFeedback;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _lastFeedback = widget.feedback;
    if (widget.feedback != null) _play(widget.feedback!);
  }

  @override
  void didUpdateWidget(covariant AnswerFeedbackAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feedback != null && widget.feedback != _lastFeedback) {
      _lastFeedback = widget.feedback;
      _play(widget.feedback!);
    }
    if (widget.feedback == null) {
      _lastFeedback = null;
      _controller.reset();
    }
  }

  void _play(bool correct) {
    _controller.stop();
    _controller.reset();
    if (correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final isCorrect = widget.feedback == true;

        if (isCorrect) {
          final scale = 1 + math.sin(t * math.pi) * 0.06 * (1 - t * 0.3);
          return Transform.scale(scale: scale, child: child);
        }

        if (widget.feedback == false) {
          final shake = math.sin(t * math.pi * 5) * 8 * (1 - t);
          return Transform.translate(offset: Offset(shake, 0), child: child);
        }

        return child!;
      },
      child: widget.child,
    );
  }
}

/// Spring progress bar урока — не LinearProgressIndicator.
class LessonSpringProgressBar extends StatefulWidget {
  const LessonSpringProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
  });

  /// 0.0 … 1.0
  final double progress;
  final double height;

  @override
  State<LessonSpringProgressBar> createState() => _LessonSpringProgressBarState();
}

class _LessonSpringProgressBarState extends State<LessonSpringProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _displayProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() => _displayProgress = _controller.value.clamp(0.0, 1.0)));
    _controller.value = widget.progress;
    _displayProgress = widget.progress;
  }

  @override
  void didUpdateWidget(covariant LessonSpringProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _springTo(widget.progress);
    }
  }

  void _springTo(double target) {
    _controller.stop();
    final simulation = SpringSimulation(IosMotion.gentle, _displayProgress, target, 0);
    _controller.animateWith(simulation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fillWidth = constraints.maxWidth * _displayProgress;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(widget.height),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: Duration.zero,
              width: fillWidth,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height),
                gradient: LinearGradient(
                  colors: [tokens.accentMuted, tokens.accent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: tokens.accent.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
