import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/utils/exercise_word_pool.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/entities/word_entity.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';

final _rng = Random(1);

class _FakeDictionaryRepo implements DictionaryRepository {
  _FakeDictionaryRepo({required this.byCategory, required this.lessonWords});

  final Map<String, List<WordEntity>> byCategory;
  final List<WordEntity> lessonWords;

  @override
  Future<List<WordEntity>> getAllWords() async => lessonWords;

  @override
  Future<List<WordEntity>> getCuratedWords() async => lessonWords;

  @override
  Future<WordEntity?> getWordById(String id) async => null;

  @override
  Future<List<WordEntity>> search(
    String query, {
    String? category,
    PartOfSpeech? pos,
  }) async => [];

  @override
  Future<List<WordEntity>> getWordsByCategory(String category) async =>
      byCategory[category] ?? [];

  @override
  Future<List<WordEntity>> getLessonWords() async => lessonWords;

  @override
  Future<List<WordEntity>> getWordsByIds(List<String> ids) async => [];
}

void main() {
  group('ExerciseWordPool', () {
    test('loadForUnit returns unit words when enough', () async {
      final repo = _FakeDictionaryRepo(
        byCategory: {
          'animals': const [
            WordEntity(
              id: 'a1',
              chechen: 'чӀа',
              russian: 'Медведь',
              category: 'animals',
            ),
            WordEntity(
              id: 'a2',
              chechen: 'чу',
              russian: 'Волк',
              category: 'animals',
            ),
            WordEntity(
              id: 'a3',
              chechen: 'лом',
              russian: 'Лев',
              category: 'animals',
            ),
          ],
        },
        lessonWords: const [],
      );

      final words = await ExerciseWordPool.loadForUnit(
        repo,
        'animals',
        minCount: 2,
        take: 2,
        rng: _rng,
      );

      expect(words.length, 2);
      expect(words.every((w) => w.category == 'animals'), isTrue);
    });

    test('loadForUnit tops up from lesson pool when unit is short', () async {
      final repo = _FakeDictionaryRepo(
        byCategory: {
          'greetings': const [
            WordEntity(
              id: 'g1',
              chechen: 'маршалла',
              russian: 'Привет',
              category: 'greetings',
            ),
          ],
        },
        lessonWords: const [
          WordEntity(
            id: 'g1',
            chechen: 'маршалла',
            russian: 'Привет',
            category: 'greetings',
          ),
          WordEntity(
            id: 'g2',
            chechen: 'баркал',
            russian: 'Спасибо',
            category: 'greetings',
          ),
          WordEntity(
            id: 'g3',
            chechen: 'хьаьлла',
            russian: 'Пока',
            category: 'greetings',
          ),
        ],
      );

      final words = await ExerciseWordPool.loadForUnit(
        repo,
        'greetings',
        minCount: 2,
        take: 3,
        rng: _rng,
      );

      expect(words.length, 3);
      expect(words.map((w) => w.id).toSet(), containsAll(['g1', 'g2', 'g3']));
    });

    test('buildQuizOptions deduplicates russian translations', () {
      const pool = [
        WordEntity(id: '1', chechen: 'бер', russian: 'Ребёнок'),
        WordEntity(id: '2', chechen: 'берa', russian: 'Ребёнок'),
        WordEntity(id: '3', chechen: 'дада', russian: 'Отец'),
        WordEntity(id: '4', chechen: 'нана', russian: 'Мать'),
        WordEntity(id: '5', chechen: 'ваша', russian: 'Сестра'),
      ];

      final options = ExerciseWordPool.buildQuizOptions(
        pool: pool,
        target: pool[0],
        optionCount: 4,
        rng: _rng,
      );

      expect(options.length, 4);
      expect(options.where((w) => w.id == '1').length, 1);
      expect(options.any((w) => w.id == '2'), isFalse);
      final labels = options
          .map((w) => w.russian.trim().toLowerCase())
          .toList();
      expect(labels.toSet().length, labels.length);
    });
  });
}
