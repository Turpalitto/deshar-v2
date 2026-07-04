import '../../domain/entities/learning_entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/asset_dictionary_datasource.dart';

class LearningPathRepositoryImpl implements LearningPathRepository {
  LearningPathRepositoryImpl(this._assets, this._dictionary);

  final AssetDictionaryDataSource _assets;
  final DictionaryRepository _dictionary;

  @override
  Future<List<LearningUnitEntity>> getUnits() async {
    final path = await _assets.loadLearningPathJson();
    final units = <LearningUnitEntity>[];
    for (final u in path) {
      final id = u['id'] as String;
      final words = await _dictionary.getWordsByCategory(id);
      units.add(LearningUnitEntity(
        id: id,
        order: u['order'] as int,
        titleRu: u['titleRu'] as String,
        titleCe: u['titleCe'] as String,
        icon: u['icon'] as String,
        requiredMastery: u['requiredMastery'] as int,
        wordIds: words.map((w) => w.id).toList(),
        enabled: u['enabled'] as bool? ?? true,
      ));
    }
    units.sort((a, b) => a.order.compareTo(b.order));
    return units;
  }

  @override
  Future<List<LessonEntity>> getLessons() async {
    final raw = await _assets.loadLessonsJson();
    return raw.map((l) {
      final words = (l['words'] as List).cast<Map<String, dynamic>>();
      return LessonEntity(
        id: l['id'] as String,
        title: l['title'] as String,
        chechenTitle: l['chechenTitle'] as String,
        icon: l['icon'] as String? ?? '📖',
        colorHex: '#1A73E8',
        wordIds: words.map((w) {
          final ce = (w['chechen'] as String).toLowerCase().replaceAll(' ', '');
          return ce; // matched at runtime by chechen text
        }).toList(),
      );
    }).toList();
  }

  @override
  Future<bool> isUnitUnlocked(String unitId) async {
    final units = await getUnits();
    final unit = units.firstWhere((u) => u.id == unitId);
    if (unit.requiredMastery == 0) return true;
    return false; // computed in provider with use case
  }
}
