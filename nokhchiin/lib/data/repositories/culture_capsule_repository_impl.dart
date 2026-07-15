import '../../domain/entities/culture_capsule.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/content_datasource.dart';

/// Культурный контент хранится отдельно от кода в assets/data, поэтому его
/// можно расширять и вычитывать с носителями языка без правок интерфейса.
class CultureCapsuleRepositoryImpl implements CultureCapsuleRepository {
  CultureCapsuleRepositoryImpl(this._source);

  final ContentDataSource _source;

  @override
  Future<List<CultureCapsule>> getAll() => _source.loadCultureCapsules();

  @override
  Future<CultureCapsule?> forUnit(String unitId) async {
    final all = await getAll();
    for (final capsule in all) {
      if (capsule.relatedUnitId == unitId) return capsule;
    }
    return null;
  }

  @override
  Future<CultureCapsule?> byId(String id) async {
    for (final c in await getAll()) {
      if (c.id == id) return c;
    }
    return null;
  }
}
