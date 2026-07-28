import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nokhchiin/core/l10n/l10n_extensions.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/services/analytics_service.dart';
import '../../core/utils/number_format.dart';
import '../../core/widgets/kids_tap_target.dart';
import '../../core/widgets/legal_links_row.dart';
import '../../domain/constants/dictionary_constants.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/analytics_event.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tokens = context.iosTokens;

    return AppScaffold(
      showOrnament: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final intro = _OnboardingIntro(
            adultTitle: l10n.adultModeTitle,
            adultSubtitle: l10n.adultModeSubtitle,
            kidsTitle: l10n.kidsModeTitle,
            kidsSubtitle: l10n.kidsModeSubtitle,
            onAdultTap: () async {
              await ref
                  .read(userProfileProvider.notifier)
                  .setMode(AppMode.adult);
              await _trackModeSelection(ref, AppMode.adult);
              if (context.mounted) {
                unawaited(context.push('/onboarding/placement'));
              }
            },
            onKidsTap: () async {
              await ref
                  .read(userProfileProvider.notifier)
                  .setMode(AppMode.kids);
              await _trackModeSelection(ref, AppMode.kids);
              if (context.mounted) _showAgePicker(context, ref);
            },
          );

          return Padding(
            padding: EdgeInsets.fromLTRB(
              wide ? 32 : 24,
              wide ? 24 : 20,
              wide ? 32 : 24,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BrandHeader(
                  title: l10n.appTitle,
                  textColor: tokens.textPrimary,
                  secondaryColor: tokens.textTertiary,
                ),
                SizedBox(height: wide ? 24 : 18),
                Expanded(
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Expanded(
                              flex: 11,
                              child: _WorldHeroPanel(expanded: true),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              flex: 9,
                              child: SingleChildScrollView(child: intro),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(
                                height: 168,
                                child: _WorldHeroPanel(),
                              ),
                              const SizedBox(height: 24),
                              intro,
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const LegalLinksRow(compact: true),
              ],
            ),
          );
        },
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
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Подберём темп и контент',
              style: TextStyle(color: tokens.textTertiary),
            ),
            const SizedBox(height: AppSpacing.lg),
            _AgeRow(
              label: l10n.age3to6,
              iconAsset: AppIcons.ageHatchling,
              age: KidsAgeGroup.age3to6,
            ),
            _AgeRow(
              label: l10n.age6to9,
              iconAsset: AppIcons.ageSprout,
              age: KidsAgeGroup.age6to9,
            ),
            _AgeRow(
              label: l10n.age9to12,
              iconAsset: AppIcons.ageLeaf,
              age: KidsAgeGroup.age9to12,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _trackModeSelection(WidgetRef ref, AppMode mode) async {
  try {
    await ref
        .read(analyticsServiceProvider)
        .track(
          AnalyticsEventName.modeSelected,
          properties: {'mode': mode.name},
        );
  } catch (_) {
    // Analytics must not block onboarding.
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.title,
    required this.textColor,
    required this.secondaryColor,
  });

  final String title;
  final Color textColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const NokhchiinAppIcon(size: 44),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Чеченский язык · ${formatThousands(dictionaryEntryCount)}+ '
                '${pluralize(dictionaryEntryCount, one: 'запись', few: 'записи', many: 'записей')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: DesignTokens.meadowMuted,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Text(
            'OFFLINE',
            style: TextStyle(
              color: DesignTokens.meadow,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorldHeroPanel extends StatelessWidget {
  const _WorldHeroPanel({this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(expanded ? 30 : 22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/brand/onboarding_world.webp',
            fit: BoxFit.cover,
            alignment: expanded ? Alignment.center : Alignment.centerRight,
            filterQuality: FilterQuality.medium,
            cacheWidth: expanded ? 1200 : 760,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC16110C)],
                stops: [0.38, 1],
              ),
            ),
          ),
          Positioned(
            left: expanded ? 26 : 16,
            right: expanded ? 26 : 16,
            bottom: expanded ? 24 : 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: const [
                    _HeroPill(label: '15 юнитов'),
                    _HeroPill(label: '8 миров'),
                    _HeroPill(label: 'Без рекламы'),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Путь к языку начинается дома',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Уроки, истории и культура в одном спокойном ритме.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 480.ms).scaleXY(begin: 0.985);
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCCF7F4EF),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF26201A),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OnboardingIntro extends StatelessWidget {
  const _OnboardingIntro({
    required this.adultTitle,
    required this.adultSubtitle,
    required this.kidsTitle,
    required this.kidsSubtitle,
    required this.onAdultTap,
    required this.onKidsTap,
  });

  final String adultTitle;
  final String adultSubtitle;
  final String kidsTitle;
  final String kidsSubtitle;
  final VoidCallback onAdultTap;
  final VoidCallback onKidsTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Сайн дог ду хьуна',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: tokens.textPrimary,
            letterSpacing: -0.7,
            height: 1.08,
          ),
        ).animate().fadeIn().slideY(begin: 0.08),
        const SizedBox(height: 10),
        Text(
          'Рады тебя видеть!',
          style: TextStyle(fontSize: 17, color: tokens.textSecondary),
        ).animate().fadeIn(delay: 60.ms),
        const SizedBox(height: 4),
        Text(
          'Выбери свой ритм — мы подберём уроки, повторение и истории специально для тебя.',
          style: TextStyle(
            fontSize: 15,
            color: tokens.textTertiary,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 28),
        _TrackCard(
          iconAsset: AppIcons.navDictionary,
          title: adultTitle,
          subtitle: adultSubtitle,
          badge: '17+',
          accent: tokens.accent,
          accentMuted: tokens.accentMuted,
          onTap: onAdultTap,
        ).animate().fadeIn(delay: 160.ms).slideX(),
        const SizedBox(height: 12),
        _TrackCard(
          iconAsset: AppIcons.gamePlay,
          title: kidsTitle,
          subtitle: kidsSubtitle,
          badge: '3–12',
          accent: DesignTokens.meadow,
          accentMuted: DesignTokens.meadowMuted,
          onTap: onKidsTap,
        ).animate().fadeIn(delay: 220.ms).slideX(),
        const SizedBox(height: 20),
        Row(
          children: [
            _FeatureTile(
              iconAsset: AppIcons.actionReview,
              label: 'Умный повтор',
            ),
            const SizedBox(width: 8),
            _FeatureTile(iconAsset: AppIcons.stateOffline, label: 'Офлайн'),
            const SizedBox(width: 8),
            _FeatureTile(
              iconAsset: AppIcons.cultureMountains,
              label: 'Культура',
            ),
          ],
        ).animate().fadeIn(delay: 280.ms),
      ],
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
                  decoration: BoxDecoration(
                    color: accentMuted,
                    borderRadius: BorderRadius.circular(15),
                  ),
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
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          NokhchiinChip(
                            label: badge,
                            color: accent,
                            background: accentMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: tokens.textTertiary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({this.emoji, this.iconAsset, required this.label})
    : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
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
              style: TextStyle(
                fontSize: 10,
                color: tokens.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeRow extends ConsumerWidget {
  const _AgeRow({
    required this.label,
    this.emoji,
    this.iconAsset,
    required this.age,
  }) : assert(emoji != null || iconAsset != null);

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
              // Лёгкий placement (3 вопроса, можно пропустить) — дети
              // диаспоры часто знают язык частично.
              unawaited(context.push('/onboarding/placement'));
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
