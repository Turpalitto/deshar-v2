import '../../domain/entities/culture_capsule.dart';
import '../../domain/repositories/repositories.dart';
import '../culture_capsule_samples.dart';

/// Пока источник — статичные заглушки (см. CultureCapsuleSamples), но UI
/// зависит только от [CultureCapsuleRepository] — переход на динамический
/// контент потребует правки только здесь.
class CultureCapsuleRepositoryImpl implements CultureCapsuleRepository {
  @override
  Future<List<CultureCapsule>> getAll() async => CultureCapsuleSamples.all;

  @override
  Future<CultureCapsule?> forUnit(String unitId) async =>
      CultureCapsuleSamples.forUnit(unitId);

  @override
  Future<CultureCapsule?> byId(String id) async {
    for (final c in CultureCapsuleSamples.all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
