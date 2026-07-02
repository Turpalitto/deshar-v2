import 'package:flutter/material.dart';
import '../design_system.dart';

/// Вариант ответа в квизе — subtle green/red borders из Figma.
class NokhchiinQuizOption extends StatelessWidget {
  const NokhchiinQuizOption({
    super.key,
    required this.label,
    required this.letter,
    required this.onTap,
    this.selected,
    this.correct,
    this.enabled = true,
  });

  final String label;
  final String letter;
  final VoidCallback? onTap;
  final bool? selected;
  final bool? correct;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final textTheme = IosTypography.of(context, tokens);

    Color bg = tokens.surface;
    Color border = const Color(0x1A3D3832);
    Color textColor = tokens.textPrimary;
    Color badgeBg = tokens.surfaceMuted;
    Color badgeFg = tokens.textTertiary;
    String badge = letter;

    if (selected == true && correct == true) {
      bg = const Color(0xFFE8F5EE);
      border = tokens.success;
      textColor = tokens.success;
      badgeBg = tokens.success;
      badgeFg = Colors.white;
      badge = '✓';
    } else if (selected == true && correct == false) {
      bg = const Color(0xFFFBF0F0);
      border = tokens.error;
      textColor = tokens.error;
      badgeBg = tokens.error;
      badgeFg = Colors.white;
      badge = '✗';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeFg,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
