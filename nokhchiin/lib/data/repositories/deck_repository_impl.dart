import 'package:uuid/uuid.dart';

import '../../domain/entities/deck_entity.dart';
import '../../domain/entities/content_metadata.dart';
import '../../domain/entities/word_progress_entity.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local_storage_datasource.dart';

class DeckRepositoryImpl implements DeckRepository {
  DeckRepositoryImpl(
    this._local,
    this._progress,
    this._dictionary, [
    this._uuid = const Uuid(),
  ]);

  final LocalDeckDataSource _local;
  final ProgressRepository _progress;
  final DictionaryRepository _dictionary;
  final Uuid _uuid;

  @override
  Future<List<DeckEntity>> getDecks() async => [
    ...DeckEntity.systemDecks,
    ...await _local.getAll(),
  ];

  @override
  Future<DeckEntity?> getDeck(String deckId) async {
    for (final deck in DeckEntity.systemDecks) {
      if (deck.id == deckId) return deck;
    }
    for (final deck in await _local.getAll()) {
      if (deck.id == deckId) return deck;
    }
    return null;
  }

  @override
  Future<DeckEntity> createDeck(String title) async {
    final normalized = title.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Deck title cannot be empty');
    }
    final deck = DeckEntity(
      id: 'custom_${_uuid.v4()}',
      title: normalized,
      isSystem: false,
      createdAt: DateTime.now(),
    );
    await _local.save(deck);
    return deck;
  }

  @override
  Future<void> deleteDeck(String deckId) async {
    final deck = await getDeck(deckId);
    if (deck == null || deck.isSystem) return;
    await _local.delete(deckId);
    final all = await _progress.getAllProgress();
    for (final progress in all.values) {
      if (!progress.deckIds.contains(deckId)) continue;
      await _progress.saveProgress(
        progress.copyWith(deckIds: {...progress.deckIds}..remove(deckId)),
      );
    }
  }

  @override
  Future<List<String>> getWordIds(String deckId, {DateTime? now}) async {
    final progress = await _progress.getAllProgress();
    switch (deckId) {
      case SystemDeckIds.core:
        final words = await _dictionary.getCuratedWords();
        return [
          for (final word in words)
            if (!word.isPhrase && word.reviewStatus.canAppearInLearning)
              word.id,
        ];
      case SystemDeckIds.phrases:
        final words = await _dictionary.getCuratedWords();
        return [
          for (final word in words)
            if (word.isPhrase && word.reviewStatus.canAppearInLearning) word.id,
        ];
      case SystemDeckIds.rare:
        final words = await _dictionary.getCuratedWords();
        return [
          for (final word in words)
            if (!word.isPhrase &&
                word.reviewStatus.canAppearInLearning &&
                (word.frequencyTier == FrequencyTier.rare ||
                    word.frequencyTier == FrequencyTier.uncommon))
              word.id,
        ];
      case SystemDeckIds.favorites:
        return [
          for (final item in progress.values)
            if (item.isFavorite) item.wordId,
        ];
      case SystemDeckIds.mistakes:
        return [
          for (final item in progress.values)
            if (item.wrongCount > 0) item.wordId,
        ];
      case SystemDeckIds.dictionary:
        return _explicitMembers(progress, deckId);
      case SystemDeckIds.newWords:
        final words = await _dictionary.getCuratedWords();
        return [
          for (final word in words)
            if (word.reviewStatus.canAppearInLearning &&
                (progress[word.id]?.mastery.isLearned ?? false) == false)
              word.id,
        ];
      case SystemDeckIds.due:
        final timestamp = now ?? DateTime.now();
        return [
          for (final item in progress.values)
            if (item.needsReviewAt(timestamp)) item.wordId,
        ];
      default:
        return _explicitMembers(progress, deckId);
    }
  }

  List<String> _explicitMembers(
    Map<String, WordProgressEntity> progress,
    String deckId,
  ) => [
    for (final item in progress.values)
      if (item.deckIds.contains(deckId)) item.wordId,
  ];

  @override
  Future<Set<String>> getDeckIdsForWord(String wordId) async {
    final progress = await _progress.getProgress(wordId);
    return {...?progress?.deckIds};
  }

  @override
  Future<void> addWord(String wordId, String deckId) async {
    if (!await _isEditableDeck(deckId)) {
      throw ArgumentError.value(deckId, 'deckId', 'Deck is not editable');
    }
    final current =
        await _progress.getProgress(wordId) ??
        WordProgressEntity(wordId: wordId);
    await _progress.saveProgress(
      current.copyWith(deckIds: {...current.deckIds, deckId}),
    );
  }

  @override
  Future<void> removeWord(String wordId, String deckId) async {
    final current = await _progress.getProgress(wordId);
    if (current == null || !current.deckIds.contains(deckId)) return;
    await _progress.saveProgress(
      current.copyWith(deckIds: {...current.deckIds}..remove(deckId)),
    );
  }

  Future<bool> _isEditableDeck(String deckId) async {
    if (deckId == SystemDeckIds.dictionary) return true;
    final deck = await getDeck(deckId);
    return deck != null && !deck.isSystem;
  }
}
