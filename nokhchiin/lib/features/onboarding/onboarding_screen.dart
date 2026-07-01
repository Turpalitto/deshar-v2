import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nokhchiin/core/l10n/l10n_extensions.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/tokens/nokhchiin_colors.dart';
import '../../core/design/theme/nokhchiin_theme.dart';
import '../../core/design/widgets/app_button.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/enums.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final skin = NokhchiinSkin.of(context);

    return AppScaffold(
      showOrnament: false,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.displayLarge,
              textAlign: TextAlign.center,
            ).animate().fadeIn().slideY(begin: 0.2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.appTagline,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: AppSpacing.xxxl),
            _ModeCard(
              title: l10n.kidsModeTitle,
              subtitle: l10n.kidsModeSubtitle,
              emoji: '🦊',
              gradient: [NokhchiinColors.kidsLeaf, NokhchiinColors.sky],
              radius: skin.cardRadius,
              onTap: () async {
                await ref.read(userProfileProvider.notifier).setMode(AppMode.kids);
                if (context.mounted) _showAgePicker(context, ref);
              },
            ).animate().fadeIn(delay: 200.ms).slideX(),
            const SizedBox(height: AppSpacing.lg),
            _ModeCard(
              title: l10n.adultModeTitle,
              subtitle: l10n.adultModeSubtitle,
              emoji: '📚',
              gradient: [NokhchiinColors.stone, NokhchiinColors.mountain],
              radius: skin.cardRadius,
              onTap: () async {
                await ref.read(userProfileProvider.notifier).setMode(AppMode.adult);
                if (context.mounted) context.go('/lesson/$kFirstLessonUnitId');
              },
            ).animate().fadeIn(delay: 300.ms).slideX(),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  void _showAgePicker(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(NokhchiinSkin.of(context).cardRadius)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.agePickerTitle, style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            _AgeButton(label: l10n.age3to6, age: KidsAgeGroup.age3to6),
            _AgeButton(label: l10n.age6to9, age: KidsAgeGroup.age6to9),
            _AgeButton(label: l10n.age9to12, age: KidsAgeGroup.age9to12),
          ],
        ),
      ),
    );
  }
}

class _AgeButton extends ConsumerWidget {
  const _AgeButton({required this.label, required this.age});
  final String label;
  final KidsAgeGroup age;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppButton(
        label: label,
        onPressed: () async {
          await ref.read(userProfileProvider.notifier).setAgeGroup(age);
          if (context.mounted) {
            Navigator.pop(context);
            context.go('/lesson/$kFirstLessonUnitId');
          }
        },
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
    required this.radius,
    required this.onTap,
  });

  final String title, subtitle, emoji;
  final List<Color> gradient;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      gradient: LinearGradient(colors: gradient),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
        ],
      ),
    );
  }
}
