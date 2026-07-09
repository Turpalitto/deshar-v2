import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/repositories.dart';

/// Локальная аналитика прогресса без сервера.
class ProgressStatsService {
  ProgressStatsService(this._progress, this._dictionary);

  final ProgressRepository _progress;
  final DictionaryRepository _dictionary;

  Future<int> languageMasteryPercent() async {
    // Знаменатель — слова из lessons.json (проверенный учебный набор),
    // не curated с keyword-майнингом и не 134k справочник.
    final lessonWords = await _dictionary.getLessonWords();
    final progress = await _progress.getAllProgress();
    final curatedTotal = lessonWords.length;
    if (curatedTotal == 0) return 0;
    final learned = progress.values
        .where((p) => p.mastery.value >= MasteryLevel.remembering.value)
        .length;
    return ((learned / curatedTotal) * 100).round().clamp(0, 100);
  }

  Future<int> curatedMasteryPercent() async {
    final progress = await _progress.getAllProgress();
    if (progress.isEmpty) return 0;
    var sum = 0;
    for (final p in progress.values) {
      sum += (p.mastery.value / MasteryLevel.mastered.value * 100).round();
    }
    return (sum / progress.length).round().clamp(0, 100);
  }

  Future<LearningUnitEntity?> findContinueUnit(List<LearningUnitEntity> units) {
    if (units.isEmpty) return Future.value(null);
    for (final u in units) {
      if (u.isUnlocked && u.masteryPercent < 100) return Future.value(u);
    }
    final unlocked = units.where((u) => u.isUnlocked).toList();
    return Future.value(unlocked.isNotEmpty ? unlocked.last : units.first);
  }

  int weekTotalXp(List<int> weeklyXp) =>
      weeklyXp.fold<int>(0, (a, b) => a + b);
}
