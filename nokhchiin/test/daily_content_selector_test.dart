import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/domain/entities/content_metadata.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/entities/word_entity.dart';
import 'package:nokhchiin/domain/entities/word_progress_entity.dart';
import 'package:nokhchiin/domain/services/daily_content_selector.dart';

const _selector = DailyContentSelector();

List<WordEntity> _content() => [
  for (var index = 0; index < 8; index++)
    WordEntity(
      id: 'common-$index',
      chechen: 'ce-$index',
      russian: 'ru-$index',
      sources: const ['lessons', 'curated'],
      reviewStatus: ReviewStatus.sourceChecked,
      frequencyTier: FrequencyTier.common,
    ),
  const WordEntity(
    id: 'rare-1',
    chechen: 'rare-ce',
    russian: 'rare-ru',
    sources: ['maciev', 'curated'],
    reviewStatus: ReviewStatus.sourceChecked,
    frequencyTier: FrequencyTier.rare,
  ),
  const WordEntity(
    id: 'phrase-1',
    chechen: 'phrase ce',
    russian: 'phrase ru',
    partOfSpeech: PartOfSpeech.phrase,
    sources: ['lessons', 'curated'],
    reviewStatus: ReviewStatus.sourceChecked,
    frequencyTier: FrequencyTier.common,
  ),
];

void main() {
  test('same calendar date produces the same curated selection', () {
    final date = DateTime(2026, 7, 28, 9);
    final first = _selector.select(
      date: date,
      curatedWords: _content(),
      progress: const {},
    );
    final reversed = _selector.select(
      date: DateTime(2026, 7, 28, 22),
      curatedWords: _content().reversed.toList(),
      progress: const {},
    );

    expect(first, isNotNull);
    expect(reversed, isNotNull);
    expect(reversed!.wordOfTheDay.id, first!.wordOfTheDay.id);
    expect(
      reversed.newWords.map((word) => word.id),
      first.newWords.map((word) => word.id),
    );
    expect(reversed.phraseOfTheDay?.id, first.phraseOfTheDay?.id);
    expect(reversed.rareWordOfTheDay?.id, first.rareWordOfTheDay?.id);
  });

  test('five new words exclude already learned entries when possible', () {
    final progress = {
      for (var index = 0; index < 3; index++)
        'common-$index': WordProgressEntity(
          wordId: 'common-$index',
          mastery: MasteryLevel.remembering,
        ),
    };

    final selection = _selector.select(
      date: DateTime(2026, 7, 28),
      curatedWords: _content(),
      progress: progress,
    )!;

    expect(selection.newWords, hasLength(5));
    expect(selection.newWords.map((word) => word.id).toSet(), hasLength(5));
    expect(
      selection.newWords.map((word) => word.id),
      isNot(contains(anyOf('common-0', 'common-1', 'common-2'))),
    );
    expect(selection.newWordsAreUnseen, isTrue);
  });

  test('fallback words are explicitly marked as reinforcement', () {
    final content = _content();
    final progress = {
      for (final word in content)
        if (!word.isPhrase)
          word.id: WordProgressEntity(
            wordId: word.id,
            mastery: MasteryLevel.remembering,
          ),
    };

    final selection = _selector.select(
      date: DateTime(2026, 7, 28),
      curatedWords: content,
      progress: progress,
    )!;

    expect(selection.newWords, hasLength(5));
    expect(selection.newWordsAreUnseen, isFalse);
  });

  test('phrase and rare cards come from explicit safe pools', () {
    final selection = _selector.select(
      date: DateTime(2026, 7, 28),
      curatedWords: _content(),
      progress: const {},
    )!;

    expect(selection.phraseOfTheDay?.id, 'phrase-1');
    expect(selection.rareWordOfTheDay?.id, 'rare-1');
    expect(selection.quizWords, hasLength(5));
  });

  test('draft content never appears in a daily selection', () {
    final selection = _selector.select(
      date: DateTime(2026, 7, 28),
      curatedWords: [
        ..._content(),
        const WordEntity(
          id: 'draft',
          chechen: 'draft-ce',
          russian: 'draft-ru',
          reviewStatus: ReviewStatus.draft,
          frequencyTier: FrequencyTier.rare,
        ),
      ],
      progress: const {},
    )!;

    expect(
      [
        selection.wordOfTheDay,
        ...selection.newWords,
        ...selection.quizWords,
        ?selection.phraseOfTheDay,
        ?selection.rareWordOfTheDay,
      ].map((word) => word.id),
      isNot(contains('draft')),
    );
  });
}
