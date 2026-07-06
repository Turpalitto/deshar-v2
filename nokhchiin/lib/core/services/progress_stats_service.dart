import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/repositories.dart';

/// Локальная аналитика прогресса без сервера.
class ProgressStatsService {
  ProgressStatsService(this._progress, this._dictionary);

  final ProgressRepository _progress;
  final DictionaryRepository _dictionary;

  Future<int> languageMasteryPercent() async {
    final all = await _dictionary.getAllWords();
    if (all.isEmpty) return 0;
    final progress = await _progress.getAllProgress();
    // Итерируем по (гораздо меньшему) прогрессу, а не по всем 134k словам
    // словаря на каждый вызов — раньше это был лишний O(134k) скан вместо
    // O(размер прогресса) (аудит §2).
    final learned = progress.values
        .where((p) => p.mastery.value >= MasteryLevel.remembering.value)
        .length;
    return ((learned / all.length) * 100).round().clamp(0, 100);
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
