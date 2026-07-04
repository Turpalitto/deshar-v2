import '../../domain/entities/entry_type.dart';
import '../../domain/entities/dictionary_entry.dart';

/// Инвертированный индекс для быстрого partial-search.
///
/// Строится один раз из всех [DictionaryEntry]. Поиск O(1) lookup
/// вместо линейного scan по 139k записей.
class DictionarySearchIndex {
  DictionarySearchIndex(List<DictionaryEntry> entries) : _all = entries {
    _build();
  }

  final List<DictionaryEntry> _all;

  /// token → множество индексов в [_all].
  final Map<String, Set<int>> _postings = {};

  int get length => _all.length;
  List<DictionaryEntry> get all => List.unmodifiable(_all);

  void _build() {
    for (var i = 0; i < _all.length; i++) {
      for (final token in _all[i].searchTokens) {
        _postings.putIfAbsent(token, () => <int>{}).add(i);
      }
    }
  }

  /// Partial match: каждое слово запроса должно быть префиксом хотя бы одного
  /// токена записи. Возвращает до [limit] записей.
  List<DictionaryEntry> search(String query, {int limit = 80, EntryType? typeFilter}) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return const [];

    final terms = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (terms.isEmpty) return const [];

    // Пересечение postings для всех термов.
    Set<int>? result;
    for (final term in terms) {
      final hit = _postings[term];
      if (hit == null) return const [];
      result = result == null ? Set.of(hit) : result.intersection(hit);
    }

    final matches = <MapEntry<int, int>>[]; // index, score
    for (final idx in result!) {
      final e = _all[idx];
      if (typeFilter != null && e.type != typeFilter) continue;
      // Score: точное совпадение слова > префикс.
      var score = 0;
      for (final term in terms) {
        if (e.searchTokens.contains(term)) score += 10;
      }
      matches.add(MapEntry(idx, score));
    }
    matches.sort((a, b) => b.value.compareTo(a.value));

    return matches.take(limit).map((m) => _all[m.key]).toList();
  }

  /// Записи по типу.
  List<DictionaryEntry> byType(EntryType type, {int limit = 200}) {
    return _all.where((e) => e.type == type).take(limit).toList();
  }

  /// Записи по категории.
  List<DictionaryEntry> byCategory(String category, {int limit = 200}) {
    return _all.where((e) => e.category == category).take(limit).toList();
  }

  /// Избранное.
  List<DictionaryEntry> favorites() => _all.where((e) => e.favorite).toList();
}
