import 'dart:math';

import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/repositories.dart';

/// Единая загрузка и подготовка слов для всех игровых упражнений.
abstract final class ExerciseWordPool {
  static Future<List<WordEntity>> loadForIds(
    DictionaryRepository repo,
    List<String> ids, {
    required int take,
    Random? rng,
  }) async {
    final words = await repo.getWordsByIds(ids);
    words.shuffle(rng ?? Random());
    return words.take(take).toList();
  }

  /// Слова юнита (lessons-first) + добор из lesson pool при нехватке.
  static Future<List<WordEntity>> loadForUnit(
    DictionaryRepository repo,
    String unitId, {
    required int minCount,
    required int take,
    Random? rng,
  }) async {
    final random = rng ?? Random();
    final unitWords = [...await repo.getWordsByCategory(unitId)];
    if (unitWords.length >= minCount) {
      unitWords.shuffle(random);
      return unitWords.take(take).toList();
    }

    final pool = [...unitWords];
    final seen = pool.map((w) => w.id).toSet();
    final lessonWords = [...await repo.getLessonWords()]..shuffle(random);
    for (final w in lessonWords) {
      if (seen.add(w.id)) pool.add(w);
      if (pool.length >= take) break;
    }
    pool.shuffle(random);
    return pool.take(take).toList();
  }

  /// Варианты квиза: правильный + дистракторы без дублей перевода.
  static List<WordEntity> buildQuizOptions({
    required List<WordEntity> pool,
    required WordEntity target,
    required int optionCount,
    Random? rng,
  }) {
    if (pool.length < optionCount) return pool;
    final random = rng ?? Random();
    final others = [...pool]..removeWhere((w) => w.id == target.id);
    others.shuffle(random);

    final seen = <String>{target.russian.trim().toLowerCase()};
    final distractors = <WordEntity>[];
    final need = optionCount - 1;
    for (final o in others) {
      final key = o.russian.trim().toLowerCase();
      if (seen.add(key)) distractors.add(o);
      if (distractors.length >= need) break;
    }

    return [target, ...distractors.take(need)]..shuffle(random);
  }
}
