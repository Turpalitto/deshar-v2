import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/asset_dictionary_datasource.dart';
import '../../data/repositories/dictionary_search_repository_impl.dart';
import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/entry_type.dart';
import '../../domain/repositories/dictionary_search_repository.dart';
import 'datasource_providers.dart';
import 'repository_providers.dart';

const _pageSize = 40;

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

/// Накопленный список результатов поиска + состояние пагинации.
///
/// В отличие от одиночной страницы из [DictionarySearchResult], [entries]
/// растёт с каждым вызовом [DictionarySearchNotifier.loadMore] — экран
/// показывает уже загруженные записи, а не заменяет их следующей порцией.
class DictionarySearchViewState {
  const DictionarySearchViewState({
    required this.entries,
    required this.page,
    required this.totalCount,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<DictionaryEntry> entries;
  final int page;
  final int totalCount;
  final bool hasMore;
  final bool isLoadingMore;

  DictionarySearchViewState copyWith({
    List<DictionaryEntry>? entries,
    int? page,
    int? totalCount,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return DictionarySearchViewState(
      entries: entries ?? this.entries,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Результаты поиска словаря (infinite scroll с накоплением страниц).
///
/// [build] следит за query/filter — при их смене Riverpod пересоздаёт
/// нотифаер с чистого листа (страница 0). [loadMore] дописывает следующую
/// страницу к уже накопленному списку, не сбрасывая его.
final dictionarySearchProvider =
    AsyncNotifierProvider.autoDispose<DictionarySearchNotifier, DictionarySearchViewState>(
  DictionarySearchNotifier.new,
);

class DictionarySearchNotifier extends AutoDisposeAsyncNotifier<DictionarySearchViewState> {
  late String _query;
  late DictionaryFilter _filter;

  @override
  Future<DictionarySearchViewState> build() async {
    _query = ref.watch(dictionaryQueryProvider);
    _filter = ref.watch(dictionaryFilterProvider);
    return _fetchPage(page: 0, existing: const []);
  }

  Future<DictionarySearchViewState> _fetchPage({
    required int page,
    required List<DictionaryEntry> existing,
  }) async {
    final result = await ref.read(dictionarySearchRepoProvider).search(
          query: _query,
          page: page,
          pageSize: _pageSize,
          typeFilter: _filter.toTypeFilter(),
          favoritesOnly: _filter == DictionaryFilter.favorites,
        );
    return DictionarySearchViewState(
      entries: [...existing, ...result.entries],
      page: result.page,
      totalCount: result.totalCount,
      hasMore: result.hasMore,
    );
  }

  /// Подгружает следующую страницу и дописывает её к списку. No-op, если
  /// страниц больше нет или подгрузка уже идёт.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _fetchPage(page: current.page + 1, existing: current.entries);
      if (!ref.mounted) return;
      state = AsyncData(next);
    } catch (_) {
      // Транзиентная ошибка подгрузки — не теряем уже показанные записи,
      // просто гасим индикатор, чтобы пользователь мог доскроллить снова.
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// Переключает избранное и правит уже накопленный список локально —
  /// без ref.invalidate, чтобы не сбрасывать пагинацию/скролл.
  Future<void> toggleFavorite(String id) async {
    final current = state.valueOrNull;
    await ref.read(dictionarySearchRepoProvider).toggleFavorite(id);
    if (current == null || !ref.mounted) return;

    final idx = current.entries.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final updated = current.entries[idx].copyWith(favorite: !current.entries[idx].favorite);

    if (_filter == DictionaryFilter.favorites && !updated.favorite) {
      final entries = [...current.entries]..removeAt(idx);
      state = AsyncData(current.copyWith(
        entries: entries,
        totalCount: current.totalCount > 0 ? current.totalCount - 1 : 0,
      ));
    } else {
      final entries = [...current.entries];
      entries[idx] = updated;
      state = AsyncData(current.copyWith(entries: entries));
    }
  }
}

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
