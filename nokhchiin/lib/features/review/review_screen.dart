import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design/widgets/reward_celebration.dart';
import '../../core/design/widgets/word_exercise_card.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../domain/constants/subscription_limits.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';

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
    final tokens = context.iosTokens;
    final accent = profile.mode == AppMode.kids ? DesignTokens.meadow : tokens.accent;

    if (!_started) {
      return AppScaffold(
        body: due.when(
          data: (words) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              children: [
                NokhchiinPageHeader(title: 'Повторение', onBack: () => context.pop()),
                const Spacer(),
                NokhchiinSurfaceCard(
                  radius: 22,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      const Text('🔄', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 20),
                      Text(
                        'Сегодня повторить',
                        style: TextStyle(fontSize: 13, color: tokens.textTertiary, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${words.length} слов',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (!profile.isPremium) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Free: ${profile.reviewsDoneToday}/${SubscriptionLimits.freeDailyReviewLimit}',
                          style: TextStyle(fontSize: 13, color: tokens.textTertiary),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                NokhchiinButton(
                  label: words.isEmpty ? 'Всё повторено' : 'Начать',
                  fullWidth: true,
                  color: accent,
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
      body: due.when(
        data: (words) {
          if (words.isEmpty) {
            return Center(
              child: Text('Всё повторено 🎉', style: TextStyle(color: tokens.textSecondary, fontSize: 17)),
            );
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                NokhchiinPageHeader(title: 'Повторение', onBack: () => setState(() => _started = false)),
                const SizedBox(height: 8),
                NokhchiinSegmentProgress(step: _index + 1, total: words.length, color: accent),
                const SizedBox(height: 8),
                Text(
                  '${_index + 1} / ${words.length}',
                  style: TextStyle(fontSize: 13, color: tokens.textTertiary, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                WordExerciseCard(word: w, categoryId: w.category ?? 'general', showRussian: _showAnswer),
                const Spacer(),
                if (!_showAnswer)
                  NokhchiinButton(
                    label: 'Показать',
                    fullWidth: true,
                    color: accent,
                    onPressed: () => setState(() => _showAnswer = true),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: NokhchiinButton(
                          label: 'Не помню',
                          color: tokens.accentMuted,
                          textColor: tokens.accent,
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: NokhchiinButton(
                          label: 'Помню ✓',
                          color: accent,
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
