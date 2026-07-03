import 'package:flutter/material.dart';
import '../design_system.dart';

/// Primary / secondary кнопка с press-scale из Figma.
class NokhchiinButton extends StatefulWidget {
  const NokhchiinButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fullWidth = false,
    this.color,
    this.textColor,
    this.small = false,
    this.child,
    this.coloredShadow = true,
  });

  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final Color? color;
  final Color? textColor;
  final bool small;
  /// Цветная тень CTA (как в Deshar): тень цвета кнопки, soft.
  final bool coloredShadow;

  @override
  State<NokhchiinButton> createState() => _NokhchiinButtonState();
}

class _NokhchiinButtonState extends State<NokhchiinButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final textTheme = IosTypography.of(context, tokens);
    final bg = widget.color ?? tokens.accent;
    final fg = widget.textColor ?? tokens.accentOn;
    final vPad = widget.small ? 12.0 : 15.0;
    final hPad = widget.small ? 20.0 : 28.0;
    final fontSize = widget.small ? 15.0 : 17.0;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onPressed != null ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.onPressed != null ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 150),
        curve: IosMotion.curveSnappy,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.fullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.coloredShadow && widget.onPressed != null
                ? [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: widget.child ??
              Text(
                widget.label!,
                style: textTheme.headlineSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                  letterSpacing: -0.2,
                ),
              ),
        ),
      ),
    );
  }
}
