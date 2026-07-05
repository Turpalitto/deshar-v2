import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/entities/word_entity.dart';
import 'package:nokhchiin/domain/entities/word_progress_entity.dart';
import 'package:nokhchiin/domain/usecases/learning_usecases.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';

// --- Fakes ---

class _FakeProgressRepo implements ProgressRepository {
  final Map<String, WordProgressEntity> _data;
  _FakeProgressRepo([Map<String, WordProgressEntity>? data]) : _data = data ?? {};

  @override
  Future<WordProgressEntity?> getProgress(String wordId) async => _data[wordId];

  @override
  Future<Map<String, WordProgressEntity>> getAllProgress() async => _data;

  @override
  Future<void> saveProgress(WordProgressEntity progress) async {
    _data[progress.wordId] = progress;
  }

  @override
  Future<List<WordProgressEntity>> getDueForReview() async =>
      _data.values.where((p) => p.needsReview).toList();

  @override
  Future<List<String>> getFavorites() async =>
      _data.values.where((p) => p.isFavorite).map((p) => p.wordId).toList();

  @override
  Future<void> toggleFavorite(String wordId) async {}
}

class _FakeDictionaryRepo implements DictionaryRepository {
  final List<WordEntity> _words;
  _FakeDictionaryRepo(this._words);

  @override
  Future<List<WordEntity>> getAllWords() async => _words;

  @override
  Future<WordEntity?> getWordById(String id) async {
    try { return _words.firstWhere((w) => w.id == id); } catch (_) { return null; }
  }

  @override
  Future<List<WordEntity>> search(String query, {String? category, PartOfSpeech? pos}) async => [];

  @override
  Future<List<WordEntity>> getWordsByCategory(String category) async =>
      _words.where((w) => w.category == category).toList();

  @override
  Future<List<WordEntity>> getWordsByIds(List<String> ids) async {
    final set = ids.toSet();
    return _words.where((w) => set.contains(w.id)).toList();
  }
}

// --- Test data ---

const _words = [
  WordEntity(id: 'w1', chechen: 'бер', russian: 'Ребёнок', category: 'family'),
  WordEntity(id: 'w2', chechen: 'дада', russian: 'Отец', category: 'family'),
  WordEntity(id: 'w3', chechen: 'нана', russian: 'Мать', category: 'family'),
  WordEntity(id: 'w4', chechen: 'цӀе', russian: 'Красный', category: 'colors'),
];

void main() {
  group('UnitMasteryPercentUseCase', () {
    test('returns 0 when no progress exists', () async {
      final useCase = UnitMasteryPercentUseCase(
        _FakeProgressRepo(),
        _FakeDictionaryRepo(_words),
      );

      expect(await useCase('family'), 0);
    });

    test('returns correct mastery percentage', () async {
      final useCase = UnitMasteryPercentUseCase(
        _FakeProgressRepo({
          'w1': const WordProgressEntity(wordId: 'w1', mastery: MasteryLevel.mastered), // 5
          'w2': const WordProgressEntity(wordId: 'w2', mastery: MasteryLevel.seen),     // 1
          'w3': const WordProgressEntity(wordId: 'w3', mastery: MasteryLevel.unseen),   // 0
        }),
        _FakeDictionaryRepo(_words),
      );

      // family: 3 words, scores: 5 + 1 + 0 = 6, max: 3 * 5 = 15
      // 6/15 = 40%
      expect(await useCase('family'), 40);
    });

    test('returns 100 when all words are mastered', () async {
      final useCase = UnitMasteryPercentUseCase(
        _FakeProgressRepo({
          'w1': const WordProgressEntity(wordId: 'w1', mastery: MasteryLevel.mastered),
          'w2': const WordProgressEntity(wordId: 'w2', mastery: MasteryLevel.mastered),
          'w3': const WordProgressEntity(wordId: 'w3', mastery: MasteryLevel.mastered),
        }),
        _FakeDictionaryRepo(_words),
      );

      expect(await useCase('family'), 100);
    });

    test('returns 0 for empty category', () async {
      final useCase = UnitMasteryPercentUseCase(
        _FakeProgressRepo(),
        _FakeDictionaryRepo(_words),
      );

      expect(await useCase('nonexistent'), 0);
    });
  });

  group('GetDueWordsUseCase', () {
    test('returns empty list when no words are due', () async {
      final useCase = GetDueWordsUseCase(
        _FakeProgressRepo(),
        _FakeDictionaryRepo(_words),
      );

      expect(await useCase(), isEmpty);
    });

    test('returns due words sorted by next review date', () async {
      final now = DateTime.now();
      final useCase = GetDueWordsUseCase(
        _FakeProgressRepo({
          'w1': WordProgressEntity(
            wordId: 'w1',
            mastery: MasteryLevel.seen,
            nextReviewAt: now.subtract(const Duration(hours: 2)),
          ),
          'w2': WordProgressEntity(
            wordId: 'w2',
            mastery: MasteryLevel.recognizing,
            nextReviewAt: now.subtract(const Duration(hours: 5)),
          ),
          'w3': const WordProgressEntity(wordId: 'w3'), // unseen, no review
        }),
        _FakeDictionaryRepo(_words),
      );

      final due = await useCase();

      expect(due.length, 2);
      final ids = due.map((w) => w.id).toSet();
      expect(ids, containsAll(['w1', 'w2']));
    });

    test('respects limit parameter', () async {
      final now = DateTime.now();
      final useCase = GetDueWordsUseCase(
        _FakeProgressRepo({
          'w1': WordProgressEntity(wordId: 'w1', mastery: MasteryLevel.seen, nextReviewAt: now.subtract(const Duration(hours: 1))),
          'w2': WordProgressEntity(wordId: 'w2', mastery: MasteryLevel.seen, nextReviewAt: now.subtract(const Duration(hours: 2))),
          'w3': WordProgressEntity(wordId: 'w3', mastery: MasteryLevel.seen, nextReviewAt: now.subtract(const Duration(hours: 3))),
        }),
        _FakeDictionaryRepo(_words),
      );

      final due = await useCase(limit: 2);
      expect(due.length, 2);
    });
  });

  group('ReviewWordUseCase', () {
    test('creates new progress for unseen word', () async {
      final repo = _FakeProgressRepo();
      final useCase = ReviewWordUseCase(repo);

      final result = await useCase('w1', 4);

      expect(result.mastery.value, greaterThan(MasteryLevel.unseen.value));
      expect(result.repetitions, 1);

      // Check it was saved
      final saved = await repo.getProgress('w1');
      expect(saved, isNotNull);
    });

    test('updates existing progress', () async {
      final repo = _FakeProgressRepo({
        'w1': const WordProgressEntity(
          wordId: 'w1',
          mastery: MasteryLevel.seen,
          repetitions: 1,
          intervalDays: 1,
        ),
      });
      final useCase = ReviewWordUseCase(repo);

      final result = await useCase('w1', 3);

      expect(result.repetitions, 2);
      expect(result.mastery.value, greaterThanOrEqualTo(MasteryLevel.recognizing.value));
    });
  });
}
