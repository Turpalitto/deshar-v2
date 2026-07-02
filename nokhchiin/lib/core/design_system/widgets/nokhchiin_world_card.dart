import 'package:flutter/material.dart';
import '../design_system.dart';

/// Карточка мира — список на экране «Миры» (Figma Make).
class NokhchiinWorldCard extends StatelessWidget {
  const NokhchiinWorldCard({
    super.key,
    required this.index,
    required this.title,
    required this.description,
    required this.emoji,
    required this.progressPercent,
    required this.lessonCount,
    required this.color,
    this.unlocked = true,
    this.onTap,
  });

  final int index;
  final String title;
  final String description;
  final String emoji;
  final int progressPercent;
  final int lessonCount;
  final Color color;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final accent = tokens.accent;

    return NokhchiinSurfaceCard(
      onTap: unlocked ? onTap : null,
      radius: 22,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.87), color.withValues(alpha: 0.6)],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'МИР $index',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                NokhchiinArcProgress(
                  progress: progressPercent / 100,
                  size: 70,
                  strokeWidth: 5,
                  color: Colors.white,
                  trackColor: Colors.white.withValues(alpha: 0.25),
                  center: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    unlocked
                        ? '$progressPercent% · $lessonCount уроков'
                        : 'Заблокировано · $lessonCount уроков',
                    style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                  ),
                ),
                if (unlocked)
                  Text(
                    'Продолжить →',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent),
                  )
                else
                  Icon(Icons.lock_outline_rounded, size: 16, color: tokens.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Компактная строка мира на главной (Figma Make).
class NokhchiinWorldRow extends StatelessWidget {
  const NokhchiinWorldRow({
    super.key,
    required this.emoji,
    required this.title,
    required this.progressPercent,
    required this.color,
    this.unlocked = true,
    this.onTap,
  });

  final String emoji;
  final String title;
  final int progressPercent;
  final Color color;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return NokhchiinSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progressPercent / 100,
                    minHeight: 4,
                    backgroundColor: tokens.surfaceMuted,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            unlocked ? '$progressPercent%' : '🔒',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
