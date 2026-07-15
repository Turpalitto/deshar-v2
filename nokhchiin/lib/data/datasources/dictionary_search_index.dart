import '../../core/utils/chechen_text_utils.dart';
import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/entry_type.dart';

/// Memory-conscious search over the bundled dictionary.
///
/// Entries already own normalized [DictionaryEntry.searchTokens]. Keeping a
/// second postings graph for 134k entries more than doubled Android memory and
/// pushed profile PSS above 650 MB. A bounded scan is a better trade-off here:
/// the UI debounces queries and only asks for the first few hundred matches.
class DictionarySearchIndex {
  DictionarySearchIndex(List<DictionaryEntry> entries) : _all = entries;

  final List<DictionaryEntry> _all;

  int get length => _all.length;
  List<DictionaryEntry> get all => List.unmodifiable(_all);

  List<DictionaryEntry> search(
    String query, {
    int limit = 80,
    EntryType? typeFilter,
  }) {
    final terms = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .map(
          (term) =>
              (term.toLowerCase(), ChechenTextUtils.normalizeForSearch(term)),
        )
        .toList();
    if (terms.isEmpty) return const [];

    final exact = <DictionaryEntry>[];
    final prefix = <DictionaryEntry>[];
    for (final entry in _all) {
      if (typeFilter != null && entry.type != typeFilter) continue;

      var allMatch = true;
      var allExact = true;
      for (final (raw, normalized) in terms) {
        final exactTerm =
            entry.searchTokens.contains(raw) ||
            entry.searchTokens.contains(normalized);
        final prefixTerm =
            exactTerm ||
            entry.searchTokens.any(
              (token) => token.startsWith(raw) || token.startsWith(normalized),
            );
        if (!prefixTerm) {
          allMatch = false;
          break;
        }
        if (!exactTerm) allExact = false;
      }
      if (!allMatch) continue;
      (allExact ? exact : prefix).add(entry);
      if (exact.length >= limit) break;
    }

    if (exact.length >= limit) return exact.take(limit).toList();
    return [...exact, ...prefix.take(limit - exact.length)];
  }

  List<DictionaryEntry> byType(EntryType type, {int limit = 200}) =>
      _all.where((entry) => entry.type == type).take(limit).toList();

  List<DictionaryEntry> byCategory(String category, {int limit = 200}) =>
      _all.where((entry) => entry.category == category).take(limit).toList();

  List<DictionaryEntry> favorites() =>
      _all.where((entry) => entry.favorite).toList();
}
