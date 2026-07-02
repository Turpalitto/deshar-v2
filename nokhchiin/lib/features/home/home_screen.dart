import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/theme/nokhchiin_theme.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/reward_celebration.dart';
import '../../core/design/widgets/week_xp_chart.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/content_providers.dart';
import '../../core/utils/world_progress_util.dart';
import '../../data/culture_capsule_samples.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';
import '../culture/culture_capsule_modal.dart';

/// Главный экран — визуал из Figma Make, логика без изменений.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value ?? const UserProfileEntity();
    final isKids = profile.mode == AppMode.kids;
    final accent = isKids ? DesignTokens.meadow : context.iosTokens.accent;
    final accentMuted = isKids ? DesignTokens.meadowMuted : context.iosTokens.accentMuted;
    final continueUnit = ref.watch(continueUnitProvider);
    final due = ref.watch(dueWordsProvider);
    final worlds = ref.watch(worldsProvider);
    final units = ref.watch(learningUnitsProvider);

    return AppScaffold(
      showOrnament: true,
      actions: [
        if (!profile.isPremium)
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined),
            onPressed: () => context.push('/paywall'),
            tooltip: 'Premium',
          ),
      ],
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _HomeHeader(
                profile: profile,
                isKids: isKids,
                accent: accent,
                accentMuted: accentMuted,
              ).animate().fadeIn(duration: 400.ms),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(
              child: continueUnit.when(
                data: (unit) => _ContinueHero(
                  unit: unit,
                  accent: accent,
                  onTap: unit != null
                      ? () => context.push('/lesson/${unit.id}')
                      : () => context.push('/path'),
                ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.08),
                loading: () => const SizedBox(height: 120, child: LoadingState()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _GiftTile(
                      emoji: '🏛️',
                      title: 'Капсула',
                      subtitle: 'Гостеприимство',
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5C3D2E), Color(0xFF8B5E3C)],
                      ),
                      lightText: true,
                      onTap: () => CultureCapsuleModal.show(
                        context,
                        CultureCapsuleSamples.hospitality,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GiftTile(
                      emoji: profile.dailyGiftClaimed ? '✅' : '🎁',
                      title: 'Подарок',
                      subtitle: profile.dailyGiftClaimed ? 'Забран' : 'Сегодня',
                      onTap: profile.dailyGiftClaimed
                          ? null
                          : () async {
                              await ref.read(userProfileProvider.notifier).claimDailyGift();
                              if (context.mounted) {
                                await RewardCelebration.show(
                                  context,
                                  emoji: '🎁',
                                  title: 'Подарок дня!',
                                  subtitle: '+15 монет · +20 XP',
                                );
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GiftTile(
                      emoji: '📖',
                      title: 'Словарь',
                      subtitle: '7 800 слов',
                      onTap: () => context.push('/dictionary'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 120.ms),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(
              child: NokhchiinSurfaceCard(
                radius: 20,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: WeekXpChart(
                  weeklyXp: profile.weeklyXp,
                  accent: accent,
                  accentMuted: accentMuted,
                ),
              ).animate().fadeIn(delay: 160.ms),
            ),
          ),
          if (due.valueOrNull?.isNotEmpty == true)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: NokhchiinSurfaceCard(
                  onTap: () => context.go('/review'),
                  child: Row(
                    children: [
                      const Text('🔄', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Повторить ${due.value!.length} слов',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'SRS · начать сеанс',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.iosTokens.textTertiary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: accent),
                    ],
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Миры',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/worlds'),
                    child: Text('Все →', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: worlds.when(
              data: (list) {
                final unitList = units.valueOrNull ?? [];
                final slice = list.take(3).toList();
                return SliverList.separated(
                  itemCount: slice.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final w = slice[i];
                    final pct = worldProgressPercent(w, unitList);
                    final unlocked = isWorldUnlocked(
                      w,
                      isPremium: profile.isPremium,
                      unlockedWorlds: profile.unlockedWorlds,
                      coins: profile.coins,
                    );
                    final gradient = (w['gradient'] as List).cast<String>();
                    final color = Color(int.parse(gradient.first.replaceFirst('#', '0xFF')));
                    return _WorldRow(
                      world: w,
                      progressPercent: pct,
                      unlocked: unlocked,
                      color: color,
                      onTap: unlocked
                          ? () {
                              ref.read(userProfileProvider.notifier).setCurrentWorld(w['id'] as String);
                              final ids = (w['units'] as List).cast<String>();
                              if (ids.isNotEmpty) context.push('/unit/${ids.first}');
                            }
                          : () => context.push('/paywall'),
                    );
                  },
                );
              },
              loading: () => const SliverToBoxAdapter(child: LoadingState()),
              error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: _QuickLink(emoji: '📚', label: 'Коллекции', onTap: () => context.push('/collections'))),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickLink(emoji: '✨', label: 'Истории', onTap: () => context.push('/stories'))),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickLink(emoji: '⌨️', label: 'Ввод', onTap: () => context.push('/typing/animals'))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.profile,
    required this.isKids,
    required this.accent,
    required this.accentMuted,
  });

  final UserProfileEntity profile;
  final bool isKids;
  final Color accent;
  final Color accentMuted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final greeting = isKids ? 'Привет, ученик 🦊' : 'Доброе утро';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(fontSize: 13, color: tokens.textTertiary, fontWeight: FontWeight.w500),
              ),
              Text(
                'Уровень ${profile.level}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _StatPill(emoji: '🔥', value: '${profile.streakDays}', color: accent, bg: accentMuted),
            const SizedBox(width: 8),
            _StatPill(
              emoji: '💰',
              value: '${profile.coins}',
              color: DesignTokens.gold,
              bg: DesignTokens.goldMuted,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.emoji,
    required this.value,
    required this.color,
    required this.bg,
  });

  final String emoji;
  final String value;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 5),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _ContinueHero extends StatelessWidget {
  const _ContinueHero({
    required this.unit,
    required this.accent,
    required this.onTap,
  });

  final LearningUnitEntity? unit;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = unit?.titleRu ?? 'Начать путь';
    final pct = unit?.masteryPercent ?? 0;
    final step = ((pct / 100) * 5).ceil().clamp(1, 5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ПРОДОЛЖИТЬ УРОК',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                NokhchiinSegmentProgress(
                  step: step,
                  color: Colors.white.withValues(alpha: 0.9),
                  trackColor: Colors.white.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 6),
                Text(
                  unit != null ? 'Урок · $step из 5 шагов' : 'Открой путь обучения',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.gradient,
    this.lightText = false,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool lightText;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? tokens.surface : null,
            borderRadius: BorderRadius.circular(16),
            border: gradient == null ? Border.all(color: tokens.separator) : null,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: lightText ? Colors.white : tokens.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: lightText ? Colors.white.withValues(alpha: 0.6) : tokens.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorldRow extends StatelessWidget {
  const _WorldRow({
    required this.world,
    required this.progressPercent,
    required this.unlocked,
    required this.color,
    this.onTap,
  });

  final Map<String, dynamic> world;
  final int progressPercent;
  final bool unlocked;
  final Color color;
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
            child: Text(world['emoji'] as String? ?? '🌍', style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  world['titleRu'] as String,
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

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.emoji, required this.label, required this.onTap});

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NokhchiinSurfaceCard(
      onTap: onTap,
      radius: 12,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
