import 'package:flutter/material.dart';
import '../../design/app_icons.dart';
import '../../design/widgets/app_icon_image.dart';
import '../../utils/number_format.dart';
import '../design_system.dart';

/// Карточка мира — список на экране «Миры» (Figma Make).
class NokhchiinWorldCard extends StatelessWidget {
  const NokhchiinWorldCard({
    super.key,
    required this.index,
    required this.title,
    required this.description,
    this.emoji,
    this.iconAsset,
    required this.progressPercent,
    required this.lessonCount,
    required this.color,
    this.unlocked = true,
    this.onTap,
  }) : assert(emoji != null || iconAsset != null);

  final int index;
  final String title;
  final String description;
  final String? emoji;
  final String? iconAsset;
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
                  center: iconAsset != null
                      ? AppIconImage(asset: iconAsset!, size: 26, color: Colors.white)
                      : Text(emoji!, style: const TextStyle(fontSize: 26)),
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
                    // pluralize вместо жёсткого «уроков»: «1 уроков» резало
                    // глаз на карте миров.
                    unlocked
                        ? '$progressPercent% · $lessonCount ${pluralize(lessonCount, one: 'урок', few: 'урока', many: 'уроков')}'
                        : 'Заблокировано · $lessonCount ${pluralize(lessonCount, one: 'урок', few: 'урока', many: 'уроков')}',
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
    this.emoji,
    this.iconAsset,
    required this.title,
    required this.progressPercent,
    required this.color,
    this.unlocked = true,
    this.onTap,
    this.semanticLabel,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String title;
  final int progressPercent;
  final Color color;
  final bool unlocked;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return NokhchiinSurfaceCard(
      onTap: onTap,
      semanticLabel: semanticLabel ?? title,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          // Сквиркл с деликатным градиентом цвета мира — глубина вместо
          // плоской заливки.
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            alignment: Alignment.center,
            child: iconAsset != null
                ? AppIconImage(asset: iconAsset!, size: 22, color: color)
                : Text(emoji!, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    if (unlocked)
                      Text(
                        '$progressPercent%',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: progressPercent > 0 ? color : tokens.textTertiary,
                        ),
                      )
                    else
                      AppIconImage(asset: AppIcons.stateLocked, size: 16, color: tokens.textTertiary),
                  ],
                ),
                const SizedBox(height: 8),
                // Свой прогресс-бар: 6px, скруглённый, с градиентом цвета
                // мира — вместо волосяного LinearProgressIndicator.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    return Stack(
                      children: [
                        Container(
                          height: 6,
                          width: w,
                          decoration: BoxDecoration(
                            color: tokens.surfaceMuted,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: const Cubic(0.32, 0.72, 0, 1),
                          height: 6,
                          width: w * (progressPercent / 100).clamp(0.0, 1.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withValues(alpha: 0.75)],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Шеврон во вложенном круге — паттерн «кнопка-в-кнопке».
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}
