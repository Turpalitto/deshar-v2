import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/entities/word_entity.dart';
import 'package:nokhchiin/domain/entities/word_progress_entity.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';
import 'package:nokhchiin/domain/usecases/learning_usecases.dart';
import 'package:nokhchiin/domain/usecases/placement_test_usecase.dart';

// --- Fakes ---

class _FakeProgressRepo implements ProgressRepository {
  final Map<String, WordProgressEntity> _data = {};

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
      _data.values.where((p) => p.repetitions > 0 && p.needsReview).toList();

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
    try {
      return _words.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
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

const _words = [
  WordEntity(id: 'w1', chechen: 'ваша', russian: 'Брат', category: 'family'),
  WordEntity(id: 'w2', chechen: 'йиша', russian: 'Сестра', category: 'family'),
  WordEntity(id: 'w3', chechen: 'нана', russian: 'Мать', category: 'family'),
  WordEntity(id: 'w4', chechen: 'цӀе', russian: 'Красный', category: 'colors'),
];

void main() {
  group('SeedUnitMasteryFromPlacementUseCase', () {
    test('seeds all words in a unit as mastered with repetitions 0', () async {
      final progress = _FakeProgressRepo();
      final useCase = SeedUnitMasteryFromPlacementUseCase(progress, _FakeDictionaryRepo(_words));

      await useCase('family');

      for (final id in ['w1', 'w2', 'w3']) {
        final p = await progress.getProgress(id);
        expect(p, isNotNull);
        expect(p!.mastery, MasteryLevel.mastered);
        expect(p.repetitions, 0);
        expect(p.seededFromPlacement, isTrue);
      }
      // Другая категория не тронута.
      expect(await progress.getProgress('w4'), isNull);
    });

    test('seeded words are excluded from the SRS due-for-review queue', () async {
      final progress = _FakeProgressRepo();
      final useCase = SeedUnitMasteryFromPlacementUseCase(progress, _FakeDictionaryRepo(_words));

      await useCase('family');

      expect(await progress.getDueForReview(), isEmpty);
    });

    test('unit mastery reads 100% after seeding', () async {
      final progress = _FakeProgressRepo();
      final dictionary = _FakeDictionaryRepo(_words);
      final useCase = SeedUnitMasteryFromPlacementUseCase(progress, dictionary);

      await useCase('family');

      final masteryPercent = await UnitMasteryPercentUseCase(progress, dictionary)('family');
      expect(masteryPercent, 100);
    });

    test('empty category seeds nothing and does not throw', () async {
      final progress = _FakeProgressRepo();
      final useCase = SeedUnitMasteryFromPlacementUseCase(progress, _FakeDictionaryRepo(_words));

      await useCase('nonexistent');

      expect(await progress.getAllProgress(), isEmpty);
    });
  });
}
