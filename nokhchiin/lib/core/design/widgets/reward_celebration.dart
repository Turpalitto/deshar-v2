import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../tokens/app_spacing.dart';
import '../../design_system/design_system.dart';

/// Премиальная анимация награды — стиль Figma Reward screen.
class RewardCelebration {
  RewardCelebration._();

  static Future<void> show(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    String? primaryAction,
    VoidCallback? onPrimary,
    String dismissLabel = 'Отлично',
    VoidCallback? onDismiss,
  }) async {
    await HapticFeedback.mediumImpact();
    if (!context.mounted) return;

    final tokens = context.iosTokens;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: tokens.background.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        return Opacity(
          opacity: anim.value,
          child: Stack(
            children: [
              const Positioned.fill(child: NokhchiinOrnament(opacity: 0.04)),
              ...List.generate(12, (i) {
                final colors = [
                  tokens.accent,
                  DesignTokens.gold,
                  DesignTokens.meadow,
                  tokens.accentMuted,
                ];
                return Positioned(
                  left: MediaQuery.sizeOf(ctx).width * (0.1 + i * 0.07),
                  top: MediaQuery.sizeOf(ctx).height * (0.15 + (i * 37 % 65) / 100),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors[i % 4].withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: 0, end: -20, duration: (1500 + i * 200).ms),
                );
              }),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 96))
                          .animate()
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1, 1),
                            duration: 600.ms,
                            curve: IosMotion.curveBouncy,
                          ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(subtitle, textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.bodyLarge),
                      const SizedBox(height: 36),
                      if (primaryAction != null && onPrimary != null) ...[
                        NokhchiinButton(label: primaryAction, fullWidth: true, onPressed: onPrimary),
                        const SizedBox(height: 10),
                      ],
                      NokhchiinButton(
                        label: dismissLabel,
                        fullWidth: true,
                        color: tokens.accentMuted,
                        textColor: tokens.accent,
                        onPressed: onDismiss ?? () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
