import '../../core/utils/chechen_text_utils.dart';
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
  ///
  /// Каждый термин ищется в двух формах — обычной lowercase (для русских
  /// токенов) и палочка-нормализованной через [ChechenTextUtils] (для
  /// чеченских, проиндексированных с заменой 1/I/l/| → Ӏ) — индекс не знает
  /// заранее, на каком языке термин, поэтому объединяем оба совпадения.
  List<DictionaryEntry> search(String query, {int limit = 80, EntryType? typeFilter}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final terms = trimmed.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (terms.isEmpty) return const [];

    final termForms = <(String raw, String normalized)>[];
    Set<int>? result;
    for (final term in terms) {
      final raw = term.toLowerCase();
      final normalized = ChechenTextUtils.normalizeForSearch(term);
      termForms.add((raw, normalized));

      final hit = <int>{...?_postings[raw]};
      if (normalized != raw) hit.addAll(_postings[normalized] ?? const {});
      if (hit.isEmpty) return const [];
      result = result == null ? hit : result.intersection(hit);
      if (result.isEmpty) return const [];
    }

    final matches = <MapEntry<int, int>>[]; // index, score
    for (final idx in result!) {
      final e = _all[idx];
      if (typeFilter != null && e.type != typeFilter) continue;
      // Score: точное совпадение слова > префикс.
      var score = 0;
      for (final (raw, normalized) in termForms) {
        final exact = e.searchTokens.contains(raw) ||
            (normalized != raw && e.searchTokens.contains(normalized));
        if (exact) score += 10;
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
