import '../../domain/entities/learning_entities.dart';

/// Агрегированные инсайты для взрослого трека.
class LearnerInsights {
  const LearnerInsights({
    required this.languageMasteryPercent,
    required this.streakDays,
    required this.level,
    required this.xp,
    required this.lessonsCompleted,
    this.weakestUnit,
  });

  final int languageMasteryPercent;
  final int streakDays;
  final int level;
  final int xp;
  final int lessonsCompleted;
  final LearningUnitEntity? weakestUnit;

  String? get weakestLabel => weakestUnit?.titleRu;
  int? get weakestPercent => weakestUnit?.masteryPercent;
}

/// Слабое место: юнит с наименьшим [LearningUnitEntity.masteryPercent]
/// среди разблокированных (mastery считается в [UnitMasteryPercentUseCase]).
abstract final class LearnerInsightsService {
  static LearnerInsights build({
    required List<LearningUnitEntity> units,
    required int languageMasteryPercent,
    required int streakDays,
    required int level,
    required int xp,
    required int lessonsCompleted,
  }) {
    return LearnerInsights(
      languageMasteryPercent: languageMasteryPercent,
      streakDays: streakDays,
      level: level,
      xp: xp,
      lessonsCompleted: lessonsCompleted,
      weakestUnit: _weakestUnlockedUnit(units),
    );
  }

  static LearningUnitEntity? _weakestUnlockedUnit(List<LearningUnitEntity> units) {
    final unlocked = units.where((u) => u.isUnlocked).toList();
    if (unlocked.isEmpty) return null;

    unlocked.sort((a, b) {
      final byMastery = a.masteryPercent.compareTo(b.masteryPercent);
      if (byMastery != 0) return byMastery;
      return a.order.compareTo(b.order);
    });
    return unlocked.first;
  }
}
