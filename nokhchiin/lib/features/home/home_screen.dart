import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/feature_flags.dart';
import '../../domain/constants/gameplay_constants.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_icon_image.dart';
import '../../core/design/tokens/app_spacing.dart'; // intentional-mix: spacing tokens; Figma widgets from design_system
// nokhchiin_theme.dart removed — unused (analyzer warning)

import '../../core/design/widgets/app_scaffold.dart'; // intentional-mix: app shell scaffold
import '../../core/design/widgets/error_state.dart'; // intentional-mix: shared error placeholder
import '../../core/design/widgets/loading_state.dart'; // intentional-mix: shared loading placeholder
import '../../core/design/widgets/reward_celebration.dart'; // intentional-mix: celebration overlay
import '../../core/design/widgets/week_xp_chart.dart'; // intentional-mix: chart widget not yet in design_system
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';

import '../../core/utils/number_format.dart';
import '../../core/utils/world_progress_util.dart';
import '../../core/router/app_router.dart' show kFirstLessonUnitId;
import '../../domain/constants/dictionary_constants.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';
import '../culture/culture_capsule_modal.dart';
import 'widgets/word_of_the_day_card.dart';

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
    // Константа вместо ref.watch(dictionaryProvider).length: подписка
    // триггерила загрузку и парсинг полного словаря (23 МБ JSON) на первом
    // кадре Home — на web это фриз UI, т.к. compute() там выполняется в
    // главном потоке. Число обновляется пайплайном tools/build_dictionary.py.
    const dictionaryCount = dictionaryWordCount;

    return AppScaffold(
      showOrnament: true,
      actions: [
        if (FeatureFlags.premiumEnabled && !profile.isPremium)
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
                    child: NokhchiinGiftTile(
                      iconAsset: AppIcons.cultureHeritage,
                      title: 'Капсула',
                      subtitle: 'Гостеприимство',
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5C3D2E), Color(0xFF8B5E3C)],
                      ),
                      lightText: true,
                      onTap: () async {
                        final capsule = await ref
                            .read(cultureCapsuleRepoProvider)
                            .byId('capsule_hospitality');
                        if (capsule != null && context.mounted) {
                          CultureCapsuleModal.show(context, capsule);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NokhchiinGiftTile(
                      iconAsset: profile.dailyGiftClaimed ? AppIcons.stateSuccess : AppIcons.rewardGift,
                      title: 'Подарок',
                      subtitle: profile.dailyGiftClaimed ? 'Забран' : 'Сегодня',
                      onTap: profile.dailyGiftClaimed
                          ? null
                          : () async {
                              await ref.read(userProfileProvider.notifier).claimDailyGift();
                              if (context.mounted) {
                                await RewardCelebration.show(
                                  context,
                                  iconAsset: AppIcons.rewardGift,
                                  title: 'Подарок дня!',
                                  subtitle: '+15 монет · +20 XP',
                                );
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NokhchiinGiftTile(
                      iconAsset: AppIcons.navDictionary,
                      title: 'Словарь',
                      // Реальное число слов вместо устаревшего хардкода
                      // "7 800" (реально ≈134k — аудит §7).
                      subtitle:
                          '${formatThousands(dictionaryCount)} ${pluralize(dictionaryCount, one: 'слово', few: 'слова', many: 'слов')}',
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
                  semanticLabel: 'Повторить ${wordsCount(due.value!.length)}, сеанс SRS',
                  child: Row(
                    children: [
                      AppIconImage(asset: AppIcons.actionReview, size: 28, color: accent),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Повторить ${wordsCount(due.value!.length)}',
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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: const SliverToBoxAdapter(child: WordOfTheDayCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Миры',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: context.iosTokens.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/worlds'),
                    style: TextButton.styleFrom(
                      backgroundColor: accentMuted.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: Text(
                      'Все →',
                      style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w700),
                    ),
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
                    final gradient = w.gradient;
                    final color = Color(int.parse(gradient.first.replaceFirst('#', '0xFF')));
                    final worldEmoji = w.emoji;
                    return NokhchiinWorldRow(
                      emoji: worldEmoji,
                      iconAsset: worldEmoji == null ? AppIcons.navWorlds : null,
                      title: w.titleRu,
                      progressPercent: pct,
                      color: color,
                      unlocked: unlocked,
                      semanticLabel: '${w.titleRu}, прогресс $pct%',
                      onTap: unlocked
                          ? () {
                              ref.read(userProfileProvider.notifier).setCurrentWorld(w.id);
                              if (w.units.isNotEmpty) context.push('/unit/${w.units.first}');
                            }
                          : FeatureFlags.premiumEnabled
                              ? () => context.push('/paywall')
                              : null,
                    );
                  },
                );
              },
              loading: () => const SliverToBoxAdapter(child: LoadingState()),
              error: (_, __) => SliverToBoxAdapter(
                child: ErrorState(
                  message: 'Не удалось загрузить миры',
                  onRetry: () => ref.invalidate(worldsProvider),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: _QuickLink(iconAsset: AppIcons.actionCollections, label: 'Коллекции', onTap: () => context.push('/collections'))),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickLink(iconAsset: AppIcons.rewardCelebration, label: 'Истории', onTap: () => context.push('/stories'))),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickLink(iconAsset: AppIcons.actionTyping, label: 'Ввод', onTap: () => context.push('/typing/$kFirstLessonUnitId'))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
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

  /// Приветствие по времени суток вместо захардкоженного «Доброе утро»,
  /// которое показывалось и ночью.
  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 6) return 'Доброй ночи';
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.iosTokens;
    final greeting = isKids ? 'Привет, ученик' : _timeGreeting();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    greeting,
                    style: TextStyle(fontSize: 13, color: tokens.textTertiary, fontWeight: FontWeight.w500),
                  ),
                  if (isKids) ...[
                    const SizedBox(width: 6),
                    const AppIconImage(asset: AppIcons.mascotFox, size: 16),
                  ],
                ],
              ),
              Text(
                'Уровень ${profile.level}',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                  letterSpacing: -0.6,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            NokhchiinStatPill(
              iconAsset: AppIcons.progressStreak,
              value: '${profile.streakDays}',
              color: accent,
              background: accentMuted,
            ),
            const SizedBox(width: 8),
            NokhchiinStatPill(
              iconAsset: AppIcons.progressCoin,
              value: '${profile.coins}',
              color: DesignTokens.gold,
              background: DesignTokens.goldMuted,
            ),
            const SizedBox(width: 8),
            NokhchiinStatPill(
              emoji: '🧊',
              value: '${profile.streakFreezeCount}',
              color: tokens.textSecondary,
              background: tokens.surfaceMuted,
              onTap: () => _showStreakFreezeSheet(context, ref, profile),
            ),
          ],
        ),
      ],
    );
  }

  void _showStreakFreezeSheet(BuildContext context, WidgetRef ref, UserProfileEntity profile) {
    final tokens = context.iosTokens;
    final atMax = profile.streakFreezeCount >= GameplayConstants.maxStreakFreezes;
    final canAfford = profile.coins >= GameplayConstants.streakFreezeCoinCost;

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
              'Заморозка стрика',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tokens.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Сохраняет твой стрик, если пропустишь один день. У тебя: ${profile.streakFreezeCount} из ${GameplayConstants.maxStreakFreezes}.',
              style: TextStyle(color: tokens.textTertiary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: atMax || !canAfford
                  ? null
                  : () async {
                      final ok = await ref.read(userProfileProvider.notifier).buyStreakFreeze();
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'Заморозка куплена' : 'Не получилось купить'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              child: Text(
                atMax
                    ? 'Уже максимум'
                    : 'Купить за ${GameplayConstants.streakFreezeCoinCost} монет',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueHero extends StatefulWidget {
  const _ContinueHero({
    required this.unit,
    required this.accent,
    required this.onTap,
  });

  final LearningUnitEntity? unit;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_ContinueHero> createState() => _ContinueHeroState();
}

class _ContinueHeroState extends State<_ContinueHero> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.unit?.titleRu ?? 'Начать путь';
    final pct = widget.unit?.masteryPercent ?? 0;
    final step = ((pct / 100) * 5).ceil().clamp(1, 5);
    final accent = widget.accent;
    // Глубокий градиент вместо плоской заливки + тонированная тень цвета
    // акцента — «дорогая» карточка с одним источником света.
    final deep = Color.lerp(accent, const Color(0xFF10241A), 0.35)!;

    return Semantics(
      button: true,
      label: 'Продолжить урок: $title, шаг $step из 5',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 220),
          curve: const Cubic(0.32, 0.72, 0, 1),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, deep],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Национальный орнамент вместо декоративных кругов.
                const Positioned.fill(
                  child: NokhchiinOrnament(opacity: 0.07, light: true),
                ),
                Positioned(
                  right: -36,
                  top: -36,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Eyebrow-метка в пилюле, а не голый текст.
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'ПРОДОЛЖИТЬ УРОК',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                NokhchiinSegmentProgress(
                                  step: step,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  trackColor: Colors.white.withValues(alpha: 0.22),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.unit != null
                                      ? 'Урок · $step из 5 шагов'
                                      : 'Открой путь обучения',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Стрелка во вложенном круге — кинетический CTA.
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    this.emoji,
    this.iconAsset,
    required this.label,
    required this.onTap,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: NokhchiinSurfaceCard(
        onTap: onTap,
        radius: 12,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          children: [
            if (iconAsset != null)
              AppIconImage(asset: iconAsset!, size: 20, color: context.iosTokens.accent)
            else
              Text(emoji!, style: const TextStyle(fontSize: 20)),
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
      ),
    );
  }
}
