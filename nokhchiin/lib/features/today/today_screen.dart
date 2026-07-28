import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens/app_spacing.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/chechen_audio_controls.dart';
import '../../domain/entities/daily_content_entity.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/entities/word_progress_entity.dart';
import '../games/flashcards_screen.dart';
import '../games/quiz_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(todayContentProvider);
    final due = ref.watch(dueWordsProvider);
    final progress = ref.watch(allProgressProvider);
    final history = ref.watch(dailyHistoryProvider);

    return AppScaffold(
      showOrnament: false,
      maxContentWidth: 1080,
      body: content.when(
        data: (selection) {
          if (selection == null) {
            return const NokhchiinEmptyState(
              iconAsset: 'assets/icons/state_empty.svg',
              title: 'Ежедневные записи пока недоступны',
            );
          }
          final allProgress =
              progress.valueOrNull ?? const <String, WordProgressEntity>{};
          final completion = _completion(
            selection,
            allProgress,
            due.valueOrNull ?? const [],
          );
          return _TodayDashboard(
            selection: selection,
            completion: completion,
            dateLabel: _dateLabel(selection.date),
            dueLabel: due.when(
              data: (items) =>
                  items.isEmpty ? 'Всё повторено' : '${items.length} записей',
              loading: () => 'Загрузка...',
              error: (_, _) => 'Не удалось загрузить',
            ),
            history: history,
          );
        },
        loading: () => const NokhchiinLoadingState(),
        error: (_, _) => NokhchiinErrorState(
          message: 'Не удалось собрать занятие на сегодня',
          onRetry: () => ref.invalidate(todayContentProvider),
        ),
      ),
    );
  }

  double _completion(
    DailyContentEntity content,
    Map<String, WordProgressEntity> progress,
    List<WordEntity> due,
  ) {
    double score = due.isEmpty ? 1 : 0;
    score += _learnedFraction(content.newWords, progress);
    score += _hasProgress(content.wordOfTheDay, progress) ? 1 : 0;
    score +=
        content.phraseOfTheDay == null ||
            _hasProgress(content.phraseOfTheDay!, progress)
        ? 1
        : 0;
    score +=
        content.rareWordOfTheDay == null ||
            _hasProgress(content.rareWordOfTheDay!, progress)
        ? 1
        : 0;
    score += _reviewedTodayFraction(content, progress);
    return (score / 6).clamp(0, 1);
  }

  double _learnedFraction(
    List<WordEntity> words,
    Map<String, WordProgressEntity> progress,
  ) {
    if (words.isEmpty) return 1;
    final learned = words.where((word) => _hasProgress(word, progress)).length;
    return learned / words.length;
  }

  bool _hasProgress(
    WordEntity word,
    Map<String, WordProgressEntity> progress,
  ) =>
      (progress[word.id]?.mastery ?? MasteryLevel.unseen) !=
      MasteryLevel.unseen;

  double _reviewedTodayFraction(
    DailyContentEntity content,
    Map<String, WordProgressEntity> progress,
  ) {
    if (content.quizWords.isEmpty) return 1;
    final reviewed = content.quizWords.where((word) {
      final date = progress[word.id]?.lastReviewedAt;
      return date != null &&
          date.year == content.date.year &&
          date.month == content.date.month &&
          date.day == content.date.day;
    }).length;
    return reviewed / content.quizWords.length;
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.${date.year}';
}

class _TodayDashboard extends StatelessWidget {
  const _TodayDashboard({
    required this.selection,
    required this.completion,
    required this.dateLabel,
    required this.dueLabel,
    required this.history,
  });

  final DailyContentEntity selection;
  final double completion;
  final String dateLabel;
  final String dueLabel;
  final AsyncValue<List<DailyContentEntity>> history;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            wide ? 28 : AppSpacing.lg,
            AppSpacing.lg,
            wide ? 28 : AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TodayHeader(dateLabel: dateLabel, completion: completion),
              const SizedBox(height: AppSpacing.lg),
              _TodayHero(
                selection: selection,
                completion: completion,
                wide: wide,
                onStart: () => context.push('/today/new'),
              ),
              const SizedBox(height: 28),
              const _SectionTitle(label: 'План на сегодня'),
              Row(
                children: [
                  Expanded(
                    child: _TaskTile(
                      icon: Icons.schedule_outlined,
                      color: DesignTokens.terracotta,
                      background: DesignTokens.terracottaMuted,
                      title: 'Просроченные повторения',
                      subtitle: dueLabel,
                      onTap: () => context.go('/review'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _TaskTile(
                      icon: Icons.add_rounded,
                      color: DesignTokens.meadow,
                      background: DesignTokens.meadowMuted,
                      title: 'Пять новых слов',
                      subtitle: '${selection.newWords.length} на сегодня',
                      onTap: () => context.push('/today/new'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionTitle(label: 'Слово дня'),
              _DailyContentLayout(selection: selection, wide: wide),
              const SizedBox(height: AppSpacing.md),
              _QuizTile(
                count: selection.quizWords.length,
                onTap: () => context.push('/today/quiz'),
              ),
              const SizedBox(height: AppSpacing.lg),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
                title: const Text(
                  'История',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                children: history.when(
                  data: (items) => [
                    for (final item in items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.wordOfTheDay.chechen),
                        subtitle: Text(
                          '${_formatDate(item.date)} · ${item.wordOfTheDay.russian}',
                        ),
                        onTap: () =>
                            context.push('/dictionary/${item.wordOfTheDay.id}'),
                      ),
                  ],
                  loading: () => const [NokhchiinLoadingState()],
                  error: (_, _) => const [],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.dateLabel, required this.completion});

  final String dateLabel;
  final double completion;

  @override
  Widget build(BuildContext context) {
    final percent = (completion * 100).round();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Сегодня',
                style: TextStyle(
                  color: context.iosTokens.textPrimary,
                  fontSize: 32,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                dateLabel,
                style: TextStyle(
                  color: context.iosTokens.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: DesignTokens.goldMuted,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '$percent% выполнено',
            style: const TextStyle(
              color: Color(0xFF755300),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.selection,
    required this.completion,
    required this.wide,
    required this.onStart,
  });

  final DailyContentEntity selection;
  final double completion;
  final bool wide;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final percent = (completion * 100).round();
    return Container(
      height: wide ? 292 : 236,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17382A).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/culture/mountain_path.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0.2, 0),
          ),
          ColoredBox(color: const Color(0xFF0C3D2C).withValues(alpha: 0.5)),
          Padding(
            padding: EdgeInsets.all(wide ? 28 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      color: DesignTokens.meadow,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ПЛАН НА СЕГОДНЯ',
                  style: TextStyle(
                    color: DesignTokens.meadowMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Пять слов до нового шага',
                  maxLines: 2,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: wide ? 30 : 23,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${selection.newWords.length} новых слов · '
                  '${selection.quizWords.length} вопросов',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.goldMuted,
                    foregroundColor: const Color(0xFF755300),
                    minimumSize: const Size(132, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded, size: 19),
                  label: const Text('Начать'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TodayNewWordsScreen extends ConsumerWidget {
  const TodayNewWordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(todayContentProvider)
        .when(
          data: (content) => content == null
              ? const AppScaffold(
                  body: NokhchiinEmptyState(
                    iconAsset: 'assets/icons/state_empty.svg',
                    title: 'Новые слова пока недоступны',
                  ),
                )
              : FlashcardsScreen(
                  unitId: 'today',
                  wordIds: content.newWords.map((word) => word.id).toList(),
                ),
          loading: () => const AppScaffold(body: NokhchiinLoadingState()),
          error: (_, _) => const AppScaffold(
            body: NokhchiinEmptyState(
              iconAsset: 'assets/icons/state_empty.svg',
              title: 'Новые слова пока недоступны',
            ),
          ),
        );
  }
}

class TodayQuizScreen extends ConsumerWidget {
  const TodayQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(todayContentProvider)
        .when(
          data: (content) => content == null
              ? const AppScaffold(
                  body: NokhchiinEmptyState(
                    iconAsset: 'assets/icons/state_empty.svg',
                    title: 'Викторина пока недоступна',
                  ),
                )
              : QuizScreen(
                  unitId: 'today',
                  maxQuestions: 5,
                  wordIds: content.quizWords.map((word) => word.id).toList(),
                ),
          loading: () => const AppScaffold(body: NokhchiinLoadingState()),
          error: (_, _) => const AppScaffold(
            body: NokhchiinEmptyState(
              iconAsset: 'assets/icons/state_empty.svg',
              title: 'Викторина пока недоступна',
            ),
          ),
        );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(label, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _DailyContentLayout extends StatelessWidget {
  const _DailyContentLayout({required this.selection, required this.wide});

  final DailyContentEntity selection;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final word = _DailyEntryCard(
      label: 'СЛОВО ДНЯ',
      word: selection.wordOfTheDay,
      color: DesignTokens.meadow,
      background: DesignTokens.meadowMuted,
    );
    final phrase = selection.phraseOfTheDay == null
        ? null
        : _DailyEntryCard(
            label: 'Фраза дня',
            word: selection.phraseOfTheDay!,
            color: DesignTokens.terracotta,
            background: DesignTokens.terracottaMuted,
            compact: true,
          );
    final rare = selection.rareWordOfTheDay == null
        ? null
        : _DailyEntryCard(
            label: 'Редкое слово дня',
            word: selection.rareWordOfTheDay!,
            color: DesignTokens.gold,
            background: DesignTokens.goldMuted,
            compact: true,
          );

    if (wide) {
      return SizedBox(
        height: 220,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 2, child: word),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                children: [
                  if (phrase != null) Expanded(child: phrase),
                  if (phrase != null && rare != null)
                    const SizedBox(height: AppSpacing.md),
                  if (rare != null) Expanded(child: rare),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(height: 120, child: word),
        if (phrase != null || rare != null) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 112,
            child: Row(
              children: [
                if (phrase != null) Expanded(child: phrase),
                if (phrase != null && rare != null)
                  const SizedBox(width: AppSpacing.md),
                if (rare != null) Expanded(child: rare),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 96),
    child: NokhchiinSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      radius: 8,
      background: background,
      border: color.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const Spacer(),
              Icon(
                Icons.arrow_forward_rounded,
                color: color.withValues(alpha: 0.7),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.iosTokens.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DailyEntryCard extends ConsumerWidget {
  const _DailyEntryCard({
    required this.label,
    required this.word,
    required this.color,
    required this.background,
    this.compact = false,
  });

  final String label;
  final WordEntity word;
  final Color color;
  final Color background;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships =
        ref.watch(wordDeckMembershipProvider(word.id)).valueOrNull ?? const {};
    final added = memberships.contains(SystemDeckIds.dictionary);
    return NokhchiinSurfaceCard(
      onTap: () => context.push('/dictionary/${word.id}'),
      padding: EdgeInsets.all(compact ? 14 : 18),
      radius: 8,
      background: background,
      border: color.withValues(alpha: 0.2),
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: compact ? 6 : 8),
                Text(
                  word.chechen,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.iosTokens.textPrimary,
                    fontSize: compact ? 17 : 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  word.russian,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.iosTokens.textSecondary),
                ),
                if (!compact) ...[
                  const SizedBox(height: 10),
                  ChechenAudioControls(audioId: word.audioId, compact: true),
                ],
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.82),
                minimumSize: const Size.square(38),
              ),
              icon: Icon(
                added ? Icons.bookmark_added : Icons.add_rounded,
                color: color,
                size: 20,
              ),
              tooltip: added ? 'Уже в карточках' : 'Добавить в карточки',
              onPressed: added
                  ? null
                  : () async {
                      await ref
                          .read(deckRepoProvider)
                          .addWord(word.id, SystemDeckIds.dictionary);
                      ref.invalidate(wordDeckMembershipProvider(word.id));
                      ref.invalidate(
                        deckWordsProvider(SystemDeckIds.dictionary),
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  const _QuizTile({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NokhchiinSurfaceCard(
      onTap: onTap,
      radius: 8,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      background: DesignTokens.skyMuted,
      border: DesignTokens.sky.withValues(alpha: 0.2),
      child: Row(
        children: [
          const Icon(Icons.quiz_outlined, color: DesignTokens.sky, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Викторина · $count вопросов',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const Icon(
            Icons.arrow_forward_rounded,
            color: DesignTokens.sky,
            size: 19,
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.'
    '${date.month.toString().padLeft(2, '0')}.${date.year}';
