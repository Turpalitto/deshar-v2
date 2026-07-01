import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/theme/nokhchiin_theme.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_chip.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/progress_ring.dart';
import '../../core/design/widgets/streak_badge.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/content_providers.dart';
import '../../core/design/widgets/reward_celebration.dart';
import '../../core/utils/world_progress_util.dart';
import '../../core/widgets/word_illustration.dart';
import '../../core/design/widgets/week_xp_chart.dart';
import '../../domain/entities/learning_entities.dart';

/// Главный экран — карта пути, кольцо прогресса, продолжение урока.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value ?? const UserProfileEntity();
    final skin = NokhchiinSkin.of(context);
    final mastery = ref.watch(languageMasteryProvider);
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
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  StreakBadge(days: profile.streakDays, compact: true),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(label: 'Ур. ${profile.level}', emoji: '⭐'),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(label: '${profile.coins}', emoji: '🪙'),
                  const Spacer(),
                  ProgressRing(
                    percent: mastery.valueOrNull ?? 0,
                    size: 52,
                    strokeWidth: 5,
                    center: const Text('❤️', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Нохчийн',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            sliver: SliverToBoxAdapter(
              child: continueUnit.when(
                data: (unit) => _ContinueHero(
                  unit: unit,
                  skin: skin,
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
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Путь', style: Theme.of(context).textTheme.headlineSmall),
                  TextButton(onPressed: () => context.push('/path'), child: const Text('Все юниты')),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: units.when(
                data: (list) => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length.clamp(0, 6),
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final u = list[i];
                    return AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      onTap: u.isUnlocked
                          ? () => context.push('/unit/${u.id}')
                          : () => context.push('/paywall?return=/'),
                      child: SizedBox(
                        width: 88,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ProgressRing(percent: u.masteryPercent, size: 36, strokeWidth: 3),
                            const SizedBox(height: 4),
                            Text(
                              u.titleRu,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 22)),
                          Text('Цель дня', style: Theme.of(context).textTheme.labelLarge),
                          Text(
                            '${profile.wordsLearnedToday} / ${profile.dailyGoalWords}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppCard(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.dailyGiftClaimed ? '✅' : '🎁', style: const TextStyle(fontSize: 22)),
                          Text('Подарок', style: Theme.of(context).textTheme.labelLarge),
                          Text(
                            profile.dailyGiftClaimed ? 'Забран' : '+15 🪙',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: AppCard(
                onTap: () => context.push('/progress'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Неделя', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    WeekXpChart(weeklyXp: profile.weeklyXp),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🌍 Миры', style: Theme.of(context).textTheme.headlineSmall),
                  TextButton(onPressed: () => context.go('/worlds'), child: const Text('Все')),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 112,
              child: worlds.when(
                data: (list) => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final w = list[i];
                    final unitList = units.valueOrNull ?? [];
                    final pct = worldProgressPercent(w, unitList);
                    final unlocked = isWorldUnlocked(
                      w,
                      isPremium: profile.isPremium,
                      unlockedWorlds: profile.unlockedWorlds,
                      coins: profile.coins,
                    );
                    return _WorldChip(
                      world: w,
                      unlocked: unlocked,
                      progressPercent: pct,
                      isActive: w['id'] == profile.currentWorldId,
                      onTap: unlocked
                          ? () {
                              ref.read(userProfileProvider.notifier).setCurrentWorld(w['id'] as String);
                              final units = (w['units'] as List).cast<String>();
                              if (units.isNotEmpty) context.push('/unit/${units.first}');
                            }
                          : () => context.push('/paywall'),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ),
          if (due.valueOrNull?.isNotEmpty == true)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
              sliver: SliverToBoxAdapter(
                child: AppCard(
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
                            Text('Начать', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_arrow_rounded, size: 36),
                    ],
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxxl),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _QuickLink(emoji: '📖', label: 'Словарь', onTap: () => context.push('/dictionary')),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QuickLink(emoji: '📚', label: 'Коллекции', onTap: () => context.push('/collections')),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QuickLink(emoji: '✨', label: 'Истории', onTap: () => context.push('/stories')),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QuickLink(emoji: '⌨️', label: 'Ввод', onTap: () => context.push('/typing/animals')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueHero extends StatelessWidget {
  const _ContinueHero({
    required this.unit,
    required this.skin,
    required this.onTap,
  });

  final LearningUnitEntity? unit;
  final NokhchiinSkin skin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = unit?.titleRu ?? 'Начать путь';
    final ce = unit?.titleCe ?? 'Маршалла';
    final pct = unit?.masteryPercent ?? 0;

    return AppCard(
      onTap: onTap,
      gradient: LinearGradient(colors: skin.heroGradient),
      child: Row(
        children: [
          if (unit != null)
            WordIllustration(category: unit!.id, emoji: null, size: skin.isKids ? 72 : 64),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Продолжить', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(ce, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ProgressRing(
            percent: pct,
            size: 56,
            strokeWidth: 5,
            center: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _WorldChip extends StatelessWidget {
  const _WorldChip({
    required this.world,
    required this.unlocked,
    required this.progressPercent,
    required this.isActive,
    this.onTap,
  });

  static const _w = 106.0;
  static const _h = 104.0;

  final Map<String, dynamic> world;
  final bool unlocked, isActive;
  final int progressPercent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = (world['gradient'] as List).cast<String>();
    final colors = gradient.map((h) => Color(int.parse(h.replaceFirst('#', '0xFF')))).toList();
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: _w,
      height: _h,
      child: Opacity(
        opacity: unlocked ? 1 : 0.5,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                boxShadow: isActive
                    ? [BoxShadow(color: primary.withValues(alpha: 0.45), blurRadius: 8, spreadRadius: 1)]
                    : null,
                border: isActive ? Border.all(color: primary, width: 2) : null,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(world['emoji'] as String? ?? '🌍', style: const TextStyle(fontSize: 26, height: 1)),
                        Text(
                          '$progressPercent%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      world['titleRu'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        height: 1.1,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unlocked ? '▶' : '🔒',
                      style: const TextStyle(fontSize: 10, height: 1, color: Color(0xFF4B5563)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.emoji, required this.label, required this.onTap});

  final String emoji, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22, height: 1)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
