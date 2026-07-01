import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../tokens/app_spacing.dart';
import 'app_button.dart';

/// Премиальная анимация награды (урок, подарок, сундук).
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

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Opacity(
          opacity: anim.value,
          child: Transform.scale(
            scale: curve.value,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.all(AppSpacing.xl),
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 72))
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.08, 1.08),
                            duration: 800.ms,
                          ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(title, style: Theme.of(ctx).textTheme.headlineSmall, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.sm),
                      Text(subtitle, style: Theme.of(ctx).textTheme.bodyLarge, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.xl),
                      if (primaryAction != null && onPrimary != null) ...[
                        AppButton(label: primaryAction, onPressed: onPrimary),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      AppButton(
                        label: dismissLabel,
                        variant: AppButtonVariant.secondary,
                        expanded: false,
                        onPressed: onDismiss ?? () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
