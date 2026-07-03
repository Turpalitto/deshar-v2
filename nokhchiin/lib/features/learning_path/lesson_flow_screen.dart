import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_button.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/app_icon_image.dart';
import '../../core/design/widgets/reward_celebration.dart';
import '../../core/design/widgets/progress_ring.dart';
import '../../core/providers/providers.dart';
import '../../domain/constants/subscription_limits.dart';
import '../culture/culture_capsule_flow.dart';
import '../games/flashcards_screen.dart';
import '../games/match_screen.dart';
import '../games/quiz_screen.dart';
import '../games/widgets/exercise_presentation.dart';

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

    if (!mounted) return;
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

    final progress = ((_step + 1) / _labels.length * 100).round();

    return AppScaffold(
      title: 'Урок · ${_labels[_step.clamp(0, _labels.length - 1)]}',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                ProgressRing(percent: progress, size: 44, strokeWidth: 4),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: LessonSpringProgressBar(
                    progress: (_step + 1) / _labels.length,
                  ),
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
                  maxQuestions: 5,
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
