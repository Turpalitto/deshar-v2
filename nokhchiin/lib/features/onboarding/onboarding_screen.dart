import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nokhchiin/core/l10n/l10n_extensions.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_icon_image.dart';
import '../../core/design/tokens/app_spacing.dart'; // intentional-mix: spacing tokens; Figma widgets from design_system
import '../../core/design/widgets/app_scaffold.dart'; // intentional-mix: app shell scaffold
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/number_format.dart';
import '../../core/widgets/kids_tap_target.dart';
import '../../core/widgets/legal_links_row.dart';
import '../../domain/constants/dictionary_constants.dart';
import '../../domain/entities/enums.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tokens = context.iosTokens;

    return AppScaffold(
      showOrnament: true,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            Row(
              children: [
                const NokhchiinAppIcon(size: 44),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      // Реальное число вместо устаревшего "7800+" (аудит §7:
                      // реально ≈134k слов после слияния с датасетом HF).
                      'Чеченский язык · ${formatThousands(dictionaryWordCount)}+ '
                      '${pluralize(dictionaryWordCount, one: 'слово', few: 'слова', many: 'слов')}',
                      style: TextStyle(fontSize: 12, color: tokens.textTertiary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36),
            Text(
              'Сайн дог ду хьуна',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
                letterSpacing: -0.4,
                height: 1.15,
              ),
            ).animate().fadeIn().slideY(begin: 0.08),
            const SizedBox(height: 10),
            Text('Рады тебя видеть!', style: TextStyle(fontSize: 17, color: tokens.textSecondary))
                .animate()
                .fadeIn(delay: 60.ms),
            const SizedBox(height: 4),
            Text(
              'Выбери трек — мы подберём уроки и темп специально для тебя.',
              style: TextStyle(fontSize: 15, color: tokens.textTertiary, height: 1.5),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 36),
            _TrackCard(
              iconAsset: AppIcons.navDictionary,
              title: l10n.adultModeTitle,
              subtitle: l10n.adultModeSubtitle,
              badge: '17+',
              accent: tokens.accent,
              accentMuted: tokens.accentMuted,
              onTap: () async {
                await ref.read(userProfileProvider.notifier).setMode(AppMode.adult);
                if (context.mounted) context.push('/onboarding/placement');
              },
            ).animate().fadeIn(delay: 160.ms).slideX(),
            const SizedBox(height: 12),
            _TrackCard(
              iconAsset: AppIcons.gamePlay,
              title: l10n.kidsModeTitle,
              subtitle: l10n.kidsModeSubtitle,
              badge: '3–12',
              accent: DesignTokens.meadow,
              accentMuted: DesignTokens.meadowMuted,
              onTap: () async {
                await ref.read(userProfileProvider.notifier).setMode(AppMode.kids);
                await ref.read(userProfileProvider.notifier).completeOnboarding();
                if (context.mounted) _showAgePicker(context, ref);
              },
            ).animate().fadeIn(delay: 220.ms).slideX(),
            const SizedBox(height: 24),
            Row(
              children: [
                _FeatureTile(iconAsset: AppIcons.actionReview, label: 'SM-2 SRS'),
                const SizedBox(width: 8),
                _FeatureTile(iconAsset: AppIcons.stateOffline, label: 'Офлайн'),
                const SizedBox(width: 8),
                _FeatureTile(iconAsset: AppIcons.cultureMountains, label: 'Культура'),
              ],
            ).animate().fadeIn(delay: 280.ms),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const LegalLinksRow(compact: true),
          ],
        ),
      ),
    );
  }

  void _showAgePicker(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tokens = context.iosTokens;
    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.agePickerTitle,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: tokens.textPrimary),
            ),
            const SizedBox(height: 8),
            Text('Подберём темп и контент', style: TextStyle(color: tokens.textTertiary)),
            const SizedBox(height: AppSpacing.lg),
            _AgeRow(label: l10n.age3to6, iconAsset: AppIcons.ageHatchling, age: KidsAgeGroup.age3to6),
            _AgeRow(label: l10n.age6to9, iconAsset: AppIcons.ageSprout, age: KidsAgeGroup.age6to9),
            _AgeRow(label: l10n.age9to12, iconAsset: AppIcons.ageLeaf, age: KidsAgeGroup.age9to12),
          ],
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    this.emoji,
    this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.accent,
    required this.accentMuted,
    required this.onTap,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String title;
  final String subtitle;
  final String badge;
  final Color accent;
  final Color accentMuted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(20),
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        child: KidsTapTarget(
        minSize: 64,
        expand: true,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.separator, width: 1.5),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: accentMuted, borderRadius: BorderRadius.circular(15)),
                alignment: Alignment.center,
                child: iconAsset != null
                    ? AppIconImage(asset: iconAsset!, size: 26, color: accent)
                    : Text(emoji!, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
                        const SizedBox(width: 8),
                        NokhchiinChip(label: badge, color: accent, background: accentMuted),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: tokens.textTertiary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: tokens.textTertiary, size: 18),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    this.emoji,
    this.iconAsset,
    required this.label,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(color: tokens.surfaceMuted, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            if (iconAsset != null)
              AppIconImage(asset: iconAsset!, size: 20, color: tokens.accent)
            else
              Text(emoji!, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: tokens.textTertiary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeRow extends ConsumerWidget {
  const _AgeRow({required this.label, this.emoji, this.iconAsset, required this.age})
      : assert(emoji != null || iconAsset != null);

  final String label;
  final String? emoji;
  final String? iconAsset;
  final KidsAgeGroup age;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.iosTokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        child: KidsTapTarget(
          minSize: 64,
          expand: true,
          onTap: () async {
            await ref.read(userProfileProvider.notifier).setAgeGroup(age);
            if (context.mounted) {
              Navigator.pop(context);
              context.go('/');
            }
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.separator, width: 1.5),
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                if (iconAsset != null)
                  AppIconImage(asset: iconAsset!, size: 32)
                else
                  Text(emoji!, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
