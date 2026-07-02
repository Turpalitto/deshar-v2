import 'package:flutter/material.dart';
import '../design_system.dart';

/// Строка настроек профиля (Figma Make).
class NokhchiinSettingsRow extends StatelessWidget {
  const NokhchiinSettingsRow({
    super.key,
    required this.emoji,
    required this.label,
    this.onTap,
    this.trailing,
  });

  final String emoji;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: tokens.textPrimary),
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded, color: tokens.textTertiary, size: 22),
          ],
        ),
      ),
    );
  }
}
