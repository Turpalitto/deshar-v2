import '../../domain/entities/daily_session_entity.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local_storage_datasource.dart';

class DailySessionRepositoryImpl implements DailySessionRepository {
  DailySessionRepositoryImpl(this._local);

  final LocalDailySessionDataSource _local;

  @override
  Future<DailySessionEntity?> getForDate(DateTime date) =>
      _local.getForDate(date);

  @override
  Future<List<DailySessionEntity>> getRecent({int limit = 7}) =>
      _local.getRecent(limit: limit);

  @override
  Future<void> save(DailySessionEntity session) => _local.save(session);
}
