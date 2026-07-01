import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Spring-first motion (iOS). По умолчанию — НЕ linear / ease.
abstract final class IosMotion {
  // --- SpringDescription (для SpringSimulation / ручных анимаций) ---

  /// Мягкое появление карточек, модалок.
  static const SpringDescription gentle = SpringDescription(
    mass: 1,
    stiffness: 170,
    damping: 19,
  );

  /// Отклик кнопок, чипов, переключений.
  static const SpringDescription snappy = SpringDescription(
    mass: 0.85,
    stiffness: 320,
    damping: 22,
  );

  /// Награда, confetti, celebration.
  static const SpringDescription bouncy = SpringDescription(
    mass: 0.7,
    stiffness: 280,
    damping: 14,
  );

  /// Закрытие / dismiss.
  static const SpringDescription settle = SpringDescription(
    mass: 1.1,
    stiffness: 220,
    damping: 26,
  );

  // --- Длительности-ориентиры (spring обычно укладывается в эти окна) ---

  static const Duration reveal = Duration(milliseconds: 420);
  static const Duration interact = Duration(milliseconds: 280);
  static const Duration celebrate = Duration(milliseconds: 650);

  // --- Curve для Animated* / flutter_animate ---

  static Curve get curveGentle => SpringMotionCurve(gentle);
  static Curve get curveSnappy => SpringMotionCurve(snappy);
  static Curve get curveBouncy => SpringMotionCurve(bouncy);
  static Curve get curveSettle => SpringMotionCurve(settle);

  /// Готовый эффект появления для flutter_animate (spring, не ease).
  static Animate Function(Animate) fadeSlideUp({
    SpringDescription spring = gentle,
    Duration? duration,
    double dy = 0.06,
  }) {
    final curve = SpringMotionCurve(spring);
    return (animate) => animate
        .fadeIn(duration: duration ?? reveal, curve: curve)
        .slideY(begin: dy, end: 0, duration: duration ?? reveal, curve: curve);
  }

  static Animate Function(Animate) scaleIn({
    SpringDescription spring = snappy,
    Duration? duration,
  }) {
    final curve = SpringMotionCurve(spring);
    return (animate) => animate.scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: duration ?? interact,
          curve: curve,
        );
  }
}

/// Curve на базе [SpringSimulation] — физический spring вместо ease.
class SpringMotionCurve extends Curve {
  const SpringMotionCurve(this.description, {this.velocity = 0});

  final SpringDescription description;
  final double velocity;

  @override
  double transformInternal(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    final simulation = SpringSimulation(description, 0, 1, velocity);
    const settleSeconds = 0.45;
    return simulation.x(t * settleSeconds).clamp(0.0, 1.0);
  }
}
