import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/app_button.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/reward_celebration.dart';
import '../../core/design/widgets/progress_ring.dart';
import '../../core/providers/providers.dart';
import '../../domain/constants/subscription_limits.dart';
import '../../domain/entities/learning_entities.dart';
import '../games/flashcards_screen.dart';
import '../games/match_screen.dart';
import '../games/quiz_screen.dart';

/// Урок: карточки → пары → квиз → награда (3–5 мин).
class LessonFlowScreen extends ConsumerStatefulWidget {
  const LessonFlowScreen({super.key, required this.unitId});
  final String unitId;

  @override
  ConsumerState<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends ConsumerState<LessonFlowScreen> {
  int _step = 0;

  static const _labels = ['Слова', 'Игра', 'Тест', 'Награда'];

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
        emoji: '🎁',
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

    await RewardCelebration.show(
      context,
      emoji: '🏆',
      title: 'Урок завершён!',
      subtitle: showChest ? '+40 XP · +10 монет · бонусы' : '+40 XP · +10 монет',
      primaryAction: hasNext ? 'Дальше: ${next.titleRu}' : null,
      onPrimary: hasNext
          ? () {
              Navigator.of(context).pop();
              context.push('/lesson/${next.id}');
            }
          : null,
      onDismiss: () {
        Navigator.of(context).pop();
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / _labels.length,
                      minHeight: 8,
                    ),
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
            const Text('🏆', style: TextStyle(fontSize: 80)),
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
