import '../../domain/entities/content_entities.dart';
import '../../domain/entities/learning_entities.dart';

/// Процент прохождения мира по mastery юнитов.
int worldProgressPercent(WorldEntity world, List<LearningUnitEntity> units) {
  final ids = world.units;
  if (ids.isEmpty || units.isEmpty) return 0;
  var sum = 0;
  var n = 0;
  for (final id in ids) {
    for (final u in units) {
      if (u.id == id) {
        sum += u.masteryPercent;
        n++;
      }
    }
  }
  return n == 0 ? 0 : (sum / n).round().clamp(0, 100);
}

bool isWorldUnlocked(
  WorldEntity world, {
  required bool isPremium,
  required List<String> unlockedWorlds,
  required int coins,
}) {
  // POLICY: до публикации — все миры открыты.
  // См. AGENTS.md → «Политика монетизации».
  return true;
}
