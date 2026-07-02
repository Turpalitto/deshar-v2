import '../../domain/entities/word_progress_entity.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local_storage_datasource.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._local);

  final LocalProgressDataSource _local;

  @override
  Future<WordProgressEntity?> getProgress(String wordId) => _local.get(wordId);

  @override
  Future<Map<String, WordProgressEntity>> getAllProgress() => _local.getAll();

  @override
  Future<void> saveProgress(WordProgressEntity progress) =>
      _local.save(progress);

  @override
  Future<List<WordProgressEntity>> getDueForReview() async {
    final all = await _local.getAll();
    return all.values.where((p) => p.needsReview).toList();
  }

  @override
  Future<List<String>> getFavorites() async {
    final all = await _local.getAll();
    return all.values.where((p) => p.isFavorite).map((p) => p.wordId).toList();
  }

  @override
  Future<void> toggleFavorite(String wordId) async {
    final p = await _local.get(wordId) ?? WordProgressEntity(wordId: wordId);
    await _local.save(p.copyWith(isFavorite: !p.isFavorite));
  }
}
