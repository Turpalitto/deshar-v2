import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_system/motion.dart';

/// Cupertino-style переход: fade + лёгкий scale (вместо Material slide).
CustomTransitionPage<T> fadeScaleTransitionPage<T>({
  required LocalKey key,
  required Widget child,
  String? name,
  Object? arguments,
  String? restorationId,
}) {
  return CustomTransitionPage<T>(
    key: key,
    name: name,
    arguments: arguments,
    restorationId: restorationId,
    transitionDuration: IosMotion.reveal,
    reverseTransitionDuration: IosMotion.interact,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Initial route: анимация не стартует → opacity 0 → «белый экран».
      if (!animation.isAnimating && animation.value == 0) {
        return child;
      }
      final curved = CurvedAnimation(parent: animation, curve: IosMotion.curveGentle);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// pageBuilder-хелпер для GoRoute.
Page<dynamic> buildFadeScalePage({
  required GoRouterState state,
  required Widget child,
}) {
  return fadeScaleTransitionPage(
    key: state.pageKey,
    name: state.name,
    arguments: state.extra,
    child: child,
  );
}
