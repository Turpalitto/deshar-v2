import 'package:flutter/material.dart';
import '../design_system.dart';

/// Chip из Figma — terracotta / gold / muted варианты.
class NokhchiinChip extends StatelessWidget {
  const NokhchiinChip({
    super.key,
    required this.label,
    this.color,
    this.background,
  });

  final String label;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? tokens.accentMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? tokens.accent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
