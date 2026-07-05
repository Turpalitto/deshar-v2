import '../../core/utils/chechen_text_utils.dart';
import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/entry_type.dart';

/// Чистый парсер сырых строк датасета → [DictionaryEntry].
///
/// Единственная ответственность: преобразовать raw row в presentation model.
/// Никакого JSON-парсинга здесь — datasource отдаёт уже декодированные Map.
/// UI никогда не вызывает этот класс напрямую.
class DictionaryParser {
  const DictionaryParser();

  /// Преобразует raw row → [DictionaryEntry].
  /// row должен содержать ключи `chechen`/`ce` и `russian`/`ru`.
  DictionaryEntry parse(Map<String, dynamic> row, {String Function(String, String)? idFactory}) {
    final ceRaw = _read(row, const ['chechen', 'ce']);
    final ruRaw = _read(row, const ['russian', 'ru']);
    final category = _read(row, const ['category'])?.trim();
    final pronunciation = _read(row, const ['pronunciation'])?.trim();
    final sourcesRaw = row['sources'];
    final sources = sourcesRaw is List
        ? sourcesRaw.map((e) => e.toString()).toList()
        : <String>[];

    final ce = _normalize(ceRaw);
    final ru = _normalize(ruRaw);

    final type = classify(ce, ru);
    final preview = _buildPreview(ce, ru, type);
    final tokens = _buildTokens(ce, ru);
    final id = idFactory != null ? idFactory(ce, ru) : _defaultId(ce, ru);

    return DictionaryEntry(
      id: id,
      type: type,
      chechen: ce,
      russian: ru,
      preview: preview,
      searchTokens: tokens,
      category: (category?.isEmpty ?? true) ? null : category,
      pronunciation: (pronunciation?.isEmpty ?? true) ? null : pronunciation,
      sources: sources,
    );
  }

  /// Автоматическая классификация по эвристикам.
  ///
  /// - 0–1 слово (без пробелов) → word
  /// - 2–4 слова, нет сказуемого → phrase
  /// - длинные с пунктуацией/> 6 слов → sentence
  /// - TODO: idiom/expression — нужны словари идиом, пока unknown
  EntryType classify(String ce, String ru) {
    final ceWords = _wordCount(ce);
    final ruWords = _wordCount(ru);
    final hasPunct = _hasSentencePunct(ce) || _hasSentencePunct(ru);
    final maxWords = ceWords > ruWords ? ceWords : ruWords;

    if (maxWords <= 1) return EntryType.word;
    if (hasPunct || maxWords > 6) return EntryType.sentence;
    if (maxWords <= 4) return EntryType.phrase;
    return EntryType.expression;
  }

  // --- Нормализация ---

  String _normalize(String? raw) {
    if (raw == null) return '';
    var s = raw;
    // Удаляем невидимые символы (BOM, zero-width, NBSP).
    s = s.replaceAll(RegExp(r'[\u200B-\u200F\uFEFF\u00A0]'), '');
    // Удаляем leading/trailing кавычки всех видов.
    final q = '"\u00AB\u00BB\u201E\u201C\u2018\u2019';
    s = s.replaceAll(RegExp('^[$q]+|[$q]+\$'), '');
    // Схлопываем множественные пробелы.
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    // Удаляем leading/trailing пунктуацию кроме осмысленной.
    s = s.trim();
    // Удаляем висячие дефисы по краям.
    s = s.replaceAll(RegExp(r'^[-–—]+|[-–—]+$'), '');
    return s.trim();
  }

  String _read(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      final v = row[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return '';
  }

  int _wordCount(String s) {
    if (s.isEmpty) return 0;
    return s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  bool _hasSentencePunct(String s) {
    return s.contains(RegExp(r'[.!?;][:]?\s*$')) ||
        s.contains(RegExp(r'[.!?;]\s'));
  }

  // --- Preview ---

  /// Preview обрезается по границе слова, никогда внутри слова.
  /// Никаких "..." в случайных местах — только в конце если обрезано.
  String _buildPreview(String ce, String ru, EntryType type) {
    if (type.isShort) return ce;
    const maxChars = 48;
    if (ce.length <= maxChars) return ce;
    final cut = ce.substring(0, maxChars);
    final lastSpace = cut.lastIndexOf(' ');
    if (lastSpace <= 0) return cut;
    return '${cut.substring(0, lastSpace)}…';
  }

  // --- Search tokens ---

  /// Токены для инвертированного индекса: каждое слово ce + ru в нижнем регистре.
  /// Плюс полные строки для match-prefix.
  Set<String> _buildTokens(String ce, String ru) {
    final tokens = <String>{};
    for (final word in ce.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      // Нормализуем ASCII-заменители палочки (1/I/l/|) в Ӏ — иначе поиск
      // не найдёт слово, если пользователь набрал его без палочки.
      // Слово уже одиночное (после split), поэтому схлопывание пробелов
      // внутри normalizeForSearch безопасно.
      final lower = ChechenTextUtils.normalizeForSearch(word);
      tokens.add(lower);
      // Префиксы для partial match (минимум 2 буквы).
      if (lower.length > 2) {
        for (var i = 2; i <= lower.length; i++) {
          tokens.add(lower.substring(0, i));
        }
      }
    }
    for (final word in ru.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final lower = word.toLowerCase();
      tokens.add(lower);
      if (lower.length > 2) {
        for (var i = 2; i <= lower.length; i++) {
          tokens.add(lower.substring(0, i));
        }
      }
    }
    return tokens;
  }

  String _defaultId(String ce, String ru) {
    return '${ce.toLowerCase().replaceAll(' ', '')}|${ru.toLowerCase().trim()}';
  }
}
