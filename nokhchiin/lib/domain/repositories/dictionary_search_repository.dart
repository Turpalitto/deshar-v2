import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/entry_type.dart';

/// Абстрактный репозиторий словаря для presentation-слоя.
///
/// Возвращает только [DictionaryEntry] — никогда сырые строки.
/// UI зависит только от этого контракта.
abstract class DictionarySearchRepository {
  /// Поиск с partial match. Пустой запрос → все записи (пагинация).
  Future<DictionarySearchResult> search({
    required String query,
    required int page,
    required int pageSize,
    EntryType? typeFilter,
    bool favoritesOnly = false,
  });

  /// Одна запись по id.
  Future<DictionaryEntry?> getById(String id);

  /// Связанные записи (та же категория или общий токен).
  Future<List<DictionaryEntry>> getRelated(String id, {int limit = 10});

  /// Избранное.
  Future<List<DictionaryEntry>> getFavorites();

  /// Переключить favorite.
  Future<void> toggleFavorite(String id);

  /// Общее число записей (для header счётчика).
  int get totalCount;
}

/// Страница результатов.
class DictionarySearchResult {
  const DictionarySearchResult({
    required this.entries,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  final List<DictionaryEntry> entries;
  final int page;
  final int pageSize;
  final int totalCount;

  bool get hasMore => (page + 1) * pageSize < totalCount;
}
