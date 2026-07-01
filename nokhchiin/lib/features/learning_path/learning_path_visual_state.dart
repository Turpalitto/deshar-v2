import '../../domain/entities/learning_entities.dart';

/// Визуальные состояния узла пути — только отображение, без логики разблокировки.
enum PathNodeVisualState { locked, current, completed }

/// Определяет «текущий» узел так же, как [ProgressStatsService.findContinueUnit].
int? currentUnitOrder(List<LearningUnitEntity> units) {
  for (final u in units) {
    if (u.isUnlocked && u.masteryPercent < 100) return u.order;
  }
  final unlocked = units.where((u) => u.isUnlocked).toList();
  if (unlocked.isNotEmpty) return unlocked.last.order;
  return units.isNotEmpty ? units.first.order : null;
}

PathNodeVisualState pathNodeVisualState(
  LearningUnitEntity unit, {
  required int? activeOrder,
}) {
  if (!unit.isUnlocked) return PathNodeVisualState.locked;
  if (activeOrder != null && unit.order == activeOrder) {
    return PathNodeVisualState.current;
  }
  return PathNodeVisualState.completed;
}
