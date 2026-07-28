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
  List<DictionaryEntry>? _coreEntries;
  DictionarySearchIndex? _coreIndex;
  Map<String, DictionaryEntry>? _coreById;
  Set<String>? _favoriteIds;
  Future<void>? _loadFuture;
  Future<void>? _coreLoadFuture;
  Object? _loadError;
  StackTrace? _loadStackTrace;
  int _activeCount = 0;

  Future<void> _ensureLoaded({required bool fullDictionary}) async {
    if (!fullDictionary) {
      if (_coreEntries != null) return;
      _coreLoadFuture ??= _loadCore();
      try {
        await _coreLoadFuture;
      } catch (_) {
        _coreLoadFuture = null;
        rethrow;
      }
      return;
    }
    if (_entries != null) return;
    _loadFuture ??= _loadFull();
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

  Future<void> _loadCore() async {
    final result = await _assets.loadCuratedWords();
    final words = switch (result) {
      Success(:final data) => data,
      Failure(:final error, :final stackTrace) => Error.throwWithStackTrace(
        error,
        stackTrace ?? StackTrace.current,
      ),
    };
    await _ensureFavoritesLoaded();
    _coreEntries = words.map(_entryFromWord).toList()
      ..sort((a, b) => a.chechen.compareTo(b.chechen));
    _coreById = {for (final entry in _coreEntries!) entry.id: entry};
    _coreIndex = DictionarySearchIndex(_coreEntries!);
  }

  Future<void> _loadFull() async {
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
          AppLogger.error(
            'DictionarySearchRepo load failed',
            error: error,
            stackTrace: stackTrace,
          );
          return;
      }

      final entries = words.map(_entryFromWord).toList();
      _assets.releaseBundledDictionaryCache();

      // Дедуп по id.
      final seen = <String>{};
      // dictionary.json уже имеет стабильный порядок сборки. Повторная
      // сортировка 134k presentation-моделей на каждом запуске не нужна.
      _entries = entries.where((e) => seen.add(e.id)).toList();

      // Favorites из Hive.
      await _ensureFavoritesLoaded();
      _entries = _entries!
          .map((e) => e.copyWith(favorite: _favoriteIds!.contains(e.id)))
          .toList();

      _byId = {for (final e in _entries!) e.id: e};
      _index = DictionarySearchIndex(_entries!);
      _loadError = null;

      debugPrint(
        'DictionarySearchRepo loaded: ${_entries!.length} entries, '
        '${_index!.length} indexed',
      );
    } catch (e, st) {
      AppLogger.error(
        'DictionarySearchRepo load failed',
        error: e,
        stackTrace: st,
      );
      _loadError = e;
      _loadStackTrace = st;
    }
  }

  DictionaryEntry _entryFromWord(WordEntity word) {
    final parser = const DictionaryParser();
    final entry = parser.parse({
      'chechen': word.chechen,
      'russian': word.russian,
      'category': word.category,
      'pronunciation': word.pronunciation,
      'sources': word.sources,
      'frequencyTier': word.frequencyTier?.name,
      'register': word.languageRegister?.name,
      'region': word.region,
      'reviewStatus': word.reviewStatus.jsonValue,
      'sourceRef': word.sourceRef,
      'exampleCe': word.exampleCe,
      'exampleRu': word.exampleRu,
      'audioId': word.audioId,
      'license': word.license,
    }, idFactory: (_, _) => word.id);
    return entry.copyWith(favorite: _favoriteIds?.contains(word.id) ?? false);
  }

  Future<void> _ensureFavoritesLoaded() async {
    _favoriteIds ??= (await _progress.getFavorites()).toSet();
  }

  @override
  int get totalCount => _activeCount;

  @override
  Future<DictionarySearchResult> search({
    required String query,
    required int page,
    required int pageSize,
    EntryType? typeFilter,
    bool favoritesOnly = false,
    bool fullDictionary = false,
  }) async {
    await _ensureLoaded(fullDictionary: fullDictionary);
    final q = query.trim();
    final index = fullDictionary ? _index! : _coreIndex!;
    final entries = fullDictionary ? _entries! : _coreEntries!;
    _activeCount = entries.length;

    List<DictionaryEntry> base;
    if (q.isEmpty) {
      base = entries;
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
    await _ensureLoaded(fullDictionary: false);
    final core = _coreById?[id];
    if (core != null) return core;
    await _ensureLoaded(fullDictionary: true);
    return _byId?[id];
  }

  @override
  Future<List<DictionaryEntry>> getRelated(String id, {int limit = 10}) async {
    await _ensureLoaded(fullDictionary: false);
    var sourceEntries = _coreEntries!;
    var entry = _coreById?[id];
    if (entry == null) {
      await _ensureLoaded(fullDictionary: true);
      sourceEntries = _entries!;
      entry = _byId?[id];
    }
    if (entry == null) return const [];

    final related = <DictionaryEntry>[];
    // По категории.
    if (entry.category != null) {
      for (final e in sourceEntries) {
        if (e.id == id) continue;
        if (e.category == entry.category) related.add(e);
        if (related.length >= limit) break;
      }
    }
    // По общим токенам (если ещё не хватает).
    if (related.length < limit) {
      for (final e in sourceEntries) {
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
    await _ensureLoaded(fullDictionary: true);
    return _entries!.where((e) => e.favorite).toList();
  }

  @override
  Future<void> toggleFavorite(String id) async {
    await _progress.toggleFavorite(id);
    await _ensureLoaded(fullDictionary: false);
    var e = _coreById?[id] ?? _byId?[id];
    if (e == null) {
      await _ensureLoaded(fullDictionary: true);
      e = _byId?[id];
    }
    if (e == null) return;
    final updated = e.copyWith(favorite: !e.favorite);
    if (_coreById?.containsKey(id) == true) {
      _coreById![id] = updated;
      final index = _coreEntries!.indexWhere((item) => item.id == id);
      if (index >= 0) _coreEntries![index] = updated;
    }
    if (_byId?.containsKey(id) == true) {
      _byId![id] = updated;
      final index = _entries!.indexWhere((item) => item.id == id);
      if (index >= 0) _entries![index] = updated;
    }
    if (updated.favorite) {
      _favoriteIds?.add(id);
    } else {
      _favoriteIds?.remove(id);
    }
    // Перестроить индекс не нужно — токены не меняются.
  }
}
