import 'package:flutter/material.dart';
import '../design_system.dart';

/// Плоская карточка с border из Figma.
class NokhchiinSurfaceCard extends StatelessWidget {
  const NokhchiinSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.background,
    this.border,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? background;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? tokens.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border ?? tokens.separator),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}
