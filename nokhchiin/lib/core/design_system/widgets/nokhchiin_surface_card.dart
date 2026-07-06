import 'package:flutter/material.dart';
import '../design_system.dart';

/// Базовая карточка дизайн-системы: волосяная тёплая обводка + мягкая
/// диффузная тень, тонированная эспрессо (не чёрным — скилл-аудит: generic
/// black box-shadow один из маркеров шаблонного дизайна). Тап — физика
/// нажатия (scale 0.98), а не только ink-склянка.
class NokhchiinSurfaceCard extends StatefulWidget {
  const NokhchiinSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.background,
    this.border,
    this.shadow = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? background;
  final Color? border;
  final bool shadow;

  @override
  State<NokhchiinSurfaceCard> createState() => _NokhchiinSurfaceCardState();
}

class _NokhchiinSurfaceCardState extends State<NokhchiinSurfaceCard> {
  bool _pressed = false;

  // Кривая «физической массы» — cubic-bezier(0.32, 0.72, 0, 1).
  static const _spring = Cubic(0.32, 0.72, 0, 1);

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    final content = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.background ?? tokens.surface,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: widget.border ?? tokens.separator),
        boxShadow: widget.shadow
            ? [
                // Тень тёплого оттенка фона, широкая и мягкая — «парящая»
                // карточка вместо жёсткого чёрного контура.
                BoxShadow(
                  color: const Color(0xFF3D3225).withValues(alpha: tokens.isDark ? 0.35 : 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF3D3225).withValues(alpha: tokens.isDark ? 0.2 : 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return content;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 220),
          curve: _spring,
          child: content,
        ),
      ),
    );
  }
}
