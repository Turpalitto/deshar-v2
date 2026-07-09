import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/design_system.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_button.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/app_icon_image.dart';
import '../../core/design/widgets/reward_celebration.dart';
import '../../core/design/widgets/progress_ring.dart';
import '../../core/providers/providers.dart';
import '../../domain/constants/subscription_limits.dart';
import '../../domain/entities/enums.dart';
import '../../core/utils/gameplay_difficulty.dart';
import '../culture/culture_capsule_flow.dart';
import '../games/flashcards_screen.dart';
import '../games/match_screen.dart';
import '../games/quiz_screen.dart';
import '../games/widgets/exercise_presentation.dart';
import '../games/widgets/game_session_widgets.dart';

/// Урок: карточки → пары → квиз → награда (3–5 мин).
class LessonFlowScreen extends ConsumerStatefulWidget {
  const LessonFlowScreen({super.key, required this.unitId});
  final String unitId;

  @override
  ConsumerState<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends ConsumerState<LessonFlowScreen> {
  int _step = 0;
  bool _introReady = false;

  static const _labels = ['Слова', 'Игра', 'Тест', 'Награда'];
  static const _subtitles = [
    'Запомни новые слова',
    'Собери пары',
    'Ответь на вопросы',
    'Забери награду',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runIntroCapsule());
  }

  Future<void> _runIntroCapsule() async {
    await CultureCapsuleFlow.maybeShowBeforeUnit(context, ref, widget.unitId);
    if (mounted) setState(() => _introReady = true);
  }

  Future<void> _finishLesson() async {
    final notifier = ref.read(userProfileProvider.notifier);
    await notifier.addXp(40, 10);
    final total = await notifier.completeLessonWithReward();
    if (total == 1) await notifier.unlockAchievement('first_lesson');

    final showChest = total % SubscriptionLimits.lessonsPerChest == 0;
    if (showChest) await notifier.openLessonChest();

    if (!mounted) return;
    if (showChest) {
      await RewardCelebration.show(
        context,
        iconAsset: AppIcons.rewardChest,
        title: 'Сундук!',
        subtitle: '+25 монет · +30 XP',
        dismissLabel: 'Круто!',
      );
    }
    if (!mounted) return;

    final units = await ref.read(learningUnitsProvider.future);
    final idx = units.indexWhere((u) => u.id == widget.unitId);
    final next = idx >= 0 && idx < units.length - 1 ? units[idx + 1] : null;
    final hasNext = next != null && next.isUnlocked;
    final isLastUnit = idx == units.length - 1;

    if (!mounted) return;

    if (isLastUnit) {
      // Путь завершён — особый экран. Аудит logic §8.
      await RewardCelebration.show(
        context,
        iconAsset: AppIcons.rewardTrophy,
        title: 'Путь завершён!',
        subtitle: 'Ты прошёл все уроки. Повторяй слова в SRS, чтобы не забыть.',
        primaryAction: 'Повторить (SRS)',
        onPrimary: () {
          Navigator.of(context).pop();
          context.go('/review');
        },
        onDismiss: () {
          Navigator.of(context).pop();
          context.go('/');
        },
      );
      return;
    }

    await RewardCelebration.show(
      context,
      iconAsset: AppIcons.rewardTrophy,
      title: 'Урок завершён!',
      subtitle: showChest ? '+40 XP · +10 монет · бонусы' : '+40 XP · +10 монет',
      primaryAction: hasNext ? 'Дальше: ${next.titleRu}' : null,
      onPrimary: hasNext
          ? () {
              Navigator.of(context).pop();
              context.go('/lesson/${next.id}');
            }
          : null,
      onDismiss: () {
        Navigator.of(context).pop();
        context.go('/');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_introReady) {
      return const AppScaffold(
        title: 'Урок',
        body: LoadingState(message: 'Готовим урок…'),
      );
    }

    final step = _step.clamp(0, _labels.length - 1);
    final progress = ((step + 1) / _labels.length * 100).round();
    final profile = ref.watch(userProfileProvider).value;
    final quizQuestions = GameplayDifficulty.lessonQuizQuestions(
      mode: profile?.mode ?? AppMode.kids,
      age: profile?.ageGroup ?? KidsAgeGroup.age6to9,
    );

    return AppScaffold(
      title: 'Урок · ${_labels[step]}',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ProgressRing(percent: progress, size: 44, strokeWidth: 4),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: LessonSpringProgressBar(
                        progress: (step + 1) / _labels.length,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ExerciseProgressHeader(
                  step: step + 1,
                  total: _labels.length,
                  label: _subtitles[step],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: List.generate(_labels.length, (i) {
                    final active = i == step;
                    final done = i < step;
                    final tokens = context.iosTokens;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 0 : AppSpacing.xs,
                          right: i == _labels.length - 1 ? 0 : AppSpacing.xs,
                        ),
                        child: NokhchiinChip(
                          label: _labels[i],
                          color: active
                              ? tokens.accentOn
                              : done
                                  ? tokens.success
                                  : tokens.textTertiary,
                          background: active
                              ? tokens.accent
                              : done
                                  ? tokens.success.withValues(alpha: 0.12)
                                  : tokens.surfaceMuted,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (_step) {
              0 => FlashcardsScreen(
                  unitId: widget.unitId,
                  embedded: true,
                  onComplete: () => setState(() => _step = 1),
                ),
              1 => MatchScreen(
                  unitId: widget.unitId,
                  embedded: true,
                  onComplete: () => setState(() => _step = 2),
                ),
              2 => QuizScreen(
                  unitId: widget.unitId,
                  embedded: true,
                  maxQuestions: quizQuestions,
                  onComplete: () => setState(() => _step = 3),
                ),
              _ => _RewardStep(onClaim: _finishLesson),
            },
          ),
        ],
      ),
    );
  }
}

class _RewardStep extends StatelessWidget {
  const _RewardStep({required this.onClaim});
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIconImage(asset: AppIcons.rewardTrophy, size: 80),
            const SizedBox(height: AppSpacing.lg),
            Text('Отлично!', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('Забери награду за урок', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(label: 'Забрать награду', onPressed: onClaim),
          ],
        ),
      ),
    );
  }
}
