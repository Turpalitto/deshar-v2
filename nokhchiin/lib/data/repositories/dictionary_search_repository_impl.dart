import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/entry_type.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/dictionary_search_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/dictionary_parser.dart';
import '../datasources/dictionary_search_index.dart';
import '../datasources/asset_dictionary_datasource.dart';

/// Реализация [DictionarySearchRepository].
///
/// Парсит сырой датасет один раз → строит [DictionarySearchIndex].
/// Поиск O(1) lookup. Пагинация slice по индексу. Favorites синхронизируются
/// с Hive через [ProgressRepository].
class DictionarySearchRepositoryImpl implements DictionarySearchRepository {
  DictionarySearchRepositoryImpl(this._assets, this._progress);

  final AssetDictionaryDataSource _assets;
  final ProgressRepository _progress;

  List<DictionaryEntry>? _entries;
  DictionarySearchIndex? _index;
  Map<String, DictionaryEntry>? _byId;
  Set<String>? _favoriteIds;
  Future<void>? _loadFuture;
  Object? _loadError;
  StackTrace? _loadStackTrace;

  Future<void> _ensureLoaded() async {
    if (_entries != null) return;
    _loadFuture ??= _load();
    await _loadFuture;
    if (_loadError != null) {
      // Не мемоизируем провал — следующий вызов должен реально повторить
      // загрузку asset'ов, а не вечно возвращать ту же ошибку из кэша.
      _loadFuture = null;
      final error = _loadError!;
      final stackTrace = _loadStackTrace;
      if (stackTrace != null) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      throw error;
    }
  }

  Future<void> _load() async {
    try {
      final result = await _assets.loadBundledDictionary();
      final List<WordEntity> words;
      switch (result) {
        case Success(:final data):
          words = data;
          break;
        case Failure(:final error, :final stackTrace):
          _loadError = error;
          _loadStackTrace = stackTrace;
          AppLogger.error('DictionarySearchRepo load failed', error: error, stackTrace: stackTrace);
          return;
      }

      // datasource возвращает List<WordEntity> из legacy parser.
      // Здесь маппим в DictionaryEntry через DictionaryParser.
      final parser = const DictionaryParser();
      final entries = <DictionaryEntry>[];

      // Сначала читаем сырой JSON напрямую для полной классификации.
      // WordEntity уже потерял часть инфо (hint, quality) — но для
      // classification достаточно ce/ru/category.
      for (final w in words) {
        final entry = parser.parse(
          {
            'chechen': w.chechen,
            'russian': w.russian,
            'category': w.category,
            'pronunciation': w.pronunciation,
            'sources': w.sources,
          },
          // Тот же id, что и в WordEntity — избранное/прогресс словаря
          // должны совпадать с играми/SRS, которые ключуются по WordEntity.id.
          idFactory: (ce, ru) => w.id,
        );
        entries.add(entry);
      }

      // Дедуп по id.
      final seen = <String>{};
      _entries = entries.where((e) => seen.add(e.id)).toList()
        ..sort((a, b) => a.chechen.compareTo(b.chechen));

      // Favorites из Hive.
      final favIds = await _progress.getFavorites();
      _favoriteIds = favIds.toSet();
      _entries = _entries!
          .map((e) => e.copyWith(favorite: _favoriteIds!.contains(e.id)))
          .toList();

      _byId = {for (final e in _entries!) e.id: e};
      _index = DictionarySearchIndex(_entries!);
      _loadError = null;

      debugPrint('DictionarySearchRepo loaded: ${_entries!.length} entries, '
          '${_index!.length} indexed');
    } catch (e, st) {
      AppLogger.error('DictionarySearchRepo load failed', error: e, stackTrace: st);
      _loadError = e;
      _loadStackTrace = st;
    }
  }

  @override
  int get totalCount => _entries?.length ?? 0;

  @override
  Future<DictionarySearchResult> search({
    required String query,
    required int page,
    required int pageSize,
    EntryType? typeFilter,
    bool favoritesOnly = false,
  }) async {
    await _ensureLoaded();
    final q = query.trim();
    final index = _index!;

    List<DictionaryEntry> base;
    if (q.isEmpty) {
      base = _entries!;
    } else {
      // typeFilter передаётся в индекс, а не пост-фильтруется: раньше
      // top-500 по score могли быть все одного типа, и пост-фильтр по
      // другому типу давал пустую страницу (аудит dictionary_search).
      base = index.search(q, limit: 500, typeFilter: typeFilter);
    }

    // Фильтры post-search.
    var filtered = base;
    if (q.isEmpty && typeFilter != null) {
      filtered = filtered.where((e) => e.type == typeFilter).toList();
    }
    if (favoritesOnly) {
      filtered = filtered.where((e) => e.favorite).toList();
    }

    final total = filtered.length;
    final start = page * pageSize;
    final slice = start < total
        ? filtered.sublist(start, (start + pageSize).clamp(0, total))
        : const <DictionaryEntry>[];

    return DictionarySearchResult(
      entries: slice,
      page: page,
      pageSize: pageSize,
      totalCount: total,
    );
  }

  @override
  Future<DictionaryEntry?> getById(String id) async {
    await _ensureLoaded();
    return _byId?[id];
  }

  @override
  Future<List<DictionaryEntry>> getRelated(String id, {int limit = 10}) async {
    await _ensureLoaded();
    final entry = _byId?[id];
    if (entry == null) return const [];

    final related = <DictionaryEntry>[];
    // По категории.
    if (entry.category != null) {
      for (final e in _entries!) {
        if (e.id == id) continue;
        if (e.category == entry.category) related.add(e);
        if (related.length >= limit) break;
      }
    }
    // По общим токенам (если ещё не хватает).
    if (related.length < limit) {
      for (final e in _entries!) {
        if (e.id == id) continue;
        if (related.any((r) => r.id == e.id)) continue;
        if (e.searchTokens.intersection(entry.searchTokens).isNotEmpty) {
          related.add(e);
        }
        if (related.length >= limit) break;
      }
    }
    return related;
  }

  @override
  Future<List<DictionaryEntry>> getFavorites() async {
    await _ensureLoaded();
    return _entries!.where((e) => e.favorite).toList();
  }

  @override
  Future<void> toggleFavorite(String id) async {
    await _progress.toggleFavorite(id);
    final e = _byId?[id];
    if (e == null) return;
    final updated = e.copyWith(favorite: !e.favorite);
    _byId![id] = updated;
    final idx = _entries!.indexWhere((x) => x.id == id);
    if (idx >= 0) _entries![idx] = updated;
    if (updated.favorite) {
      _favoriteIds?.add(id);
    } else {
      _favoriteIds?.remove(id);
    }
    // Перестроить индекс не нужно — токены не меняются.
  }
}
