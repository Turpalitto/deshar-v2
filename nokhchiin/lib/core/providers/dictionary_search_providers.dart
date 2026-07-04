import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/asset_dictionary_datasource.dart';
import '../../data/repositories/dictionary_search_repository_impl.dart';
import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/entry_type.dart';
import '../../domain/repositories/dictionary_search_repository.dart';
import 'datasource_providers.dart';
import 'repository_providers.dart';

/// Глобальный репозиторий словаря (search + pagination + favorites).
/// Живёт весь app lifecycle — не autoDispose: индекс дорогой.
final dictionarySearchRepoProvider = Provider<DictionarySearchRepository>((ref) {
  return DictionarySearchRepositoryImpl(
    ref.watch(assetDictSourceProvider),
    ref.watch(progressRepoProvider),
  );
});

/// Фильтр экрана словаря.
final dictionaryFilterProvider = StateProvider<DictionaryFilter>((_) => DictionaryFilter.all);

/// Запрос поиска.
final dictionaryQueryProvider = StateProvider<String>((_) => '');

/// Страница пагинации.
final dictionaryPageProvider = StateProvider<int>((_) => 0);

/// Результаты поиска (autoDispose: пересоздаётся при выходе с экрана).
final dictionarySearchResultProvider =
    FutureProvider.autoDispose<DictionarySearchResult>((ref) async {
  final repo = ref.watch(dictionarySearchRepoProvider);
  final query = ref.watch(dictionaryQueryProvider);
  final filter = ref.watch(dictionaryFilterProvider);
  final page = ref.watch(dictionaryPageProvider);

  return repo.search(
    query: query,
    page: page,
    pageSize: 40,
    typeFilter: filter.toTypeFilter(),
    favoritesOnly: filter == DictionaryFilter.favorites,
  );
});

/// Запись по id (для detail screen).
final dictionaryEntryProvider =
    FutureProvider.autoDispose.family<DictionaryEntry?, String>((ref, id) async {
  return ref.watch(dictionarySearchRepoProvider).getById(id);
});

/// Связанные записи.
final dictionaryRelatedProvider =
    FutureProvider.autoDispose.family<List<DictionaryEntry>, String>((ref, id) async {
  return ref.watch(dictionarySearchRepoProvider).getRelated(id);
});

/// Total count.
final dictionaryTotalCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(dictionarySearchRepoProvider);
  // Триггерим загрузку.
  await repo.search(query: '', page: 0, pageSize: 1);
  return repo.totalCount;
});

enum DictionaryFilter {
  all,
  words,
  phrases,
  sentences,
  favorites,
  ;

  String get label => switch (this) {
        all => 'Все',
        words => 'Слова',
        phrases => 'Фразы',
        sentences => 'Предложения',
        favorites => 'Избранное',
      };

  EntryType? toTypeFilter() => switch (this) {
        words => EntryType.word,
        phrases => EntryType.phrase,
        sentences => EntryType.sentence,
        _ => null,
      };
}
