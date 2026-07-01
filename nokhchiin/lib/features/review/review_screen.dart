import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/app_button.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/word_exercise_card.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/learning_entities.dart';
import '../../domain/constants/subscription_limits.dart';
import '../../core/design/widgets/reward_celebration.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _started = false;
  int _index = 0;
  bool _showAnswer = false;
  int _correct = 0;

  Future<bool> _canReview() async {
    final profile = ref.read(userProfileProvider).value ?? const UserProfileEntity();
    return ref.read(canStartReviewUseCaseProvider)(
      reviewsDoneToday: profile.reviewsDoneToday,
    );
  }

  @override
  Widget build(BuildContext context) {
    final due = ref.watch(dueWordsProvider);
    final profile = ref.watch(userProfileProvider).value ?? const UserProfileEntity();

    if (!_started) {
      return AppScaffold(
        title: 'Повторение',
        body: due.when(
          data: (words) => Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const Spacer(),
                AppCard(
                  child: Column(
                    children: [
                      const Text('🔄', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Сегодня повторить',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        '${words.length} слов',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      if (!profile.isPremium) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Free: ${profile.reviewsDoneToday}/${SubscriptionLimits.freeDailyReviewLimit}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                AppButton(
                  label: words.isEmpty ? 'Всё повторено' : 'Начать',
                  onPressed: words.isEmpty
                      ? () => context.pop()
                      : () async {
                          final ok = await _canReview();
                          if (!ok && mounted) {
                            context.push('/paywall?return=/review');
                            return;
                          }
                          setState(() => _started = true);
                        },
                ),
              ],
            ),
          ),
          loading: () => const LoadingState(),
          error: (e, _) => Center(child: Text('$e')),
        ),
      );
    }

    return AppScaffold(
      title: 'Повторение',
      body: due.when(
        data: (words) {
          if (words.isEmpty) {
            return const Center(child: Text('Всё повторено 🎉'));
          }

          if (_index >= words.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await ref.read(userProfileProvider.notifier).addXp(_correct * 5, _correct);
              if (!mounted) return;
              await RewardCelebration.show(
                context,
                emoji: '🎉',
                title: 'Отлично!',
                subtitle: 'Правильно: $_correct · +${_correct * 5} XP',
                onDismiss: () => Navigator.of(context).pop(),
              );
            });
            return const LoadingState();
          }

          final w = words[_index];
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text('${_index + 1} / ${words.length}', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                WordExerciseCard(word: w, categoryId: w.category ?? 'general', showRussian: _showAnswer),
                const Spacer(),
                if (!_showAnswer)
                  AppButton(label: 'Показать', onPressed: () => setState(() => _showAnswer = true))
                else
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Не помню',
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            await ref.read(reviewWordUseCaseProvider)(w.id, 1);
                            await ref.read(userProfileProvider.notifier).recordReview();
                            setState(() {
                              _showAnswer = false;
                              _index++;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          label: 'Помню ✓',
                          onPressed: () async {
                            await ref.read(reviewWordUseCaseProvider)(w.id, 5);
                            await ref.read(userProfileProvider.notifier).recordReview();
                            _correct++;
                            setState(() {
                              _showAnswer = false;
                              _index++;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
