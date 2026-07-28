import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nokhchiin/data/datasources/local_storage_datasource.dart';
import 'package:nokhchiin/data/repositories/deck_repository_impl.dart';
import 'package:nokhchiin/data/repositories/progress_repository_impl.dart';
import 'package:nokhchiin/domain/entities/deck_entity.dart';
import 'package:nokhchiin/domain/entities/content_metadata.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/entities/word_entity.dart';
import 'package:nokhchiin/domain/entities/word_progress_entity.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';
import 'package:nokhchiin/domain/services/spaced_repetition_engine.dart';

class _Dictionary implements DictionaryRepository {
  static const words = [
    WordEntity(
      id: 'core',
      chechen: 'core-ce',
      russian: 'core-ru',
      sources: ['lessons', 'curated'],
      reviewStatus: ReviewStatus.sourceChecked,
      frequencyTier: FrequencyTier.common,
    ),
    WordEntity(
      id: 'phrase',
      chechen: 'phrase ce',
      russian: 'phrase ru',
      partOfSpeech: PartOfSpeech.phrase,
      sources: ['lessons', 'curated'],
      reviewStatus: ReviewStatus.sourceChecked,
      frequencyTier: FrequencyTier.common,
    ),
    WordEntity(
      id: 'rare',
      chechen: 'rare-ce',
      russian: 'rare-ru',
      sources: ['maciev', 'curated'],
      reviewStatus: ReviewStatus.sourceChecked,
      frequencyTier: FrequencyTier.rare,
    ),
    WordEntity(
      id: 'uncommon',
      chechen: 'uncommon-ce',
      russian: 'uncommon-ru',
      sources: ['maciev', 'curated'],
      reviewStatus: ReviewStatus.sourceChecked,
      frequencyTier: FrequencyTier.uncommon,
    ),
  ];

  @override
  Future<List<WordEntity>> getAllWords() async => words;

  @override
  Future<List<WordEntity>> getCuratedWords() async => words;

  @override
  Future<List<WordEntity>> getLessonWords() async => words;

  @override
  Future<WordEntity?> getWordById(String id) async {
    for (final word in words) {
      if (word.id == id) return word;
    }
    return null;
  }

  @override
  Future<List<WordEntity>> getWordsByIds(List<String> ids) async {
    final byId = {for (final word in words) word.id: word};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  @override
  Future<List<WordEntity>> getWordsByCategory(String category) async => words;

  @override
  Future<List<WordEntity>> search(
    String query, {
    String? category,
    PartOfSpeech? pos,
  }) async => words;
}

void main() {
  late Directory hiveDirectory;
  late LocalProgressDataSource progressSource;
  late LocalDeckDataSource deckSource;
  late ProgressRepositoryImpl progress;
  late DeckRepositoryImpl decks;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'nokhchiin_decks_test_',
    );
    Hive.init(hiveDirectory.path);
    progressSource = LocalProgressDataSource();
    deckSource = LocalDeckDataSource();
    await progressSource.init();
    await deckSource.init();
    progress = ProgressRepositoryImpl(progressSource);
    decks = DeckRepositoryImpl(deckSource, progress, _Dictionary());
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('builds all system decks from curated words and progress', () async {
    final now = DateTime(2026, 7, 28, 12);
    await progress.saveProgress(
      WordProgressEntity(
        wordId: 'core',
        isFavorite: true,
        wrongCount: 2,
        nextReviewAt: now.subtract(const Duration(minutes: 1)),
      ),
    );

    expect(
      (await decks.getDecks()).where((deck) => deck.isSystem),
      hasLength(8),
    );
    expect(await decks.getWordIds(SystemDeckIds.core), [
      'core',
      'rare',
      'uncommon',
    ]);
    expect(await decks.getWordIds(SystemDeckIds.phrases), ['phrase']);
    expect(await decks.getWordIds(SystemDeckIds.rare), ['rare', 'uncommon']);
    expect(await decks.getWordIds(SystemDeckIds.favorites), ['core']);
    expect(await decks.getWordIds(SystemDeckIds.mistakes), ['core']);
    expect(await decks.getWordIds(SystemDeckIds.due, now: now), ['core']);
  });

  test('custom membership survives closing and reopening Hive boxes', () async {
    final custom = await decks.createDeck('Семья');
    await decks.addWord('core', custom.id);

    await Hive.box<Map>(LocalProgressDataSource.boxName).close();
    await Hive.box<Map>(LocalDeckDataSource.boxName).close();
    await progressSource.init();
    await deckSource.init();
    progress = ProgressRepositoryImpl(progressSource);
    decks = DeckRepositoryImpl(deckSource, progress, _Dictionary());

    expect((await decks.getDeck(custom.id))?.title, 'Семья');
    expect(await decks.getWordIds(custom.id), ['core']);
    expect(await decks.getDeckIdsForWord('core'), contains(custom.id));
  });

  test('dictionary deck supports add and remove', () async {
    await decks.addWord('rare', SystemDeckIds.dictionary);
    expect(await decks.getWordIds(SystemDeckIds.dictionary), ['rare']);

    await decks.removeWord('rare', SystemDeckIds.dictionary);
    expect(await decks.getWordIds(SystemDeckIds.dictionary), isEmpty);
  });

  test('deleting custom deck preserves learning progress', () async {
    final custom = await decks.createDeck('Удаляемая');
    await progress.saveProgress(
      const WordProgressEntity(
        wordId: 'core',
        mastery: MasteryLevel.remembering,
        repetitions: 3,
      ),
    );
    await decks.addWord('core', custom.id);

    await decks.deleteDeck(custom.id);

    expect(await decks.getDeck(custom.id), isNull);
    final restored = await progress.getProgress('core');
    expect(restored?.mastery, MasteryLevel.remembering);
    expect(restored?.repetitions, 3);
    expect(restored?.deckIds, isNot(contains(custom.id)));
  });

  test(
    'adult workflow persists review and dictionary deck membership',
    () async {
      final now = DateTime(2026, 7, 28, 12);
      final due = WordProgressEntity(
        wordId: 'core',
        nextReviewAt: now.subtract(const Duration(minutes: 1)),
      );
      await progress.saveProgress(due);

      expect(await progress.getDueForReview(now: now), hasLength(1));
      final reviewed = const SpacedRepetitionEngine().review(due, 4, now: now);
      await progress.saveProgress(reviewed);
      await decks.addWord('rare', SystemDeckIds.dictionary);

      await Hive.box<Map>(LocalProgressDataSource.boxName).close();
      await Hive.box<Map>(LocalDeckDataSource.boxName).close();
      await progressSource.init();
      await deckSource.init();
      progress = ProgressRepositoryImpl(progressSource);
      decks = DeckRepositoryImpl(deckSource, progress, _Dictionary());

      expect((await progress.getProgress('core'))?.repetitions, 1);
      expect(await decks.getWordIds(SystemDeckIds.dictionary), ['rare']);
    },
  );
}
