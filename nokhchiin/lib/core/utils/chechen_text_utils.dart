/// Нормализация чеченского текста для поиска (палочка Ӏ и варианты ввода).
abstract final class ChechenTextUtils {
  /// U+04CF CYRILLIC LETTER PALOCHKA
  static const palochka = '\u04CF';

  /// Нормализует ввод для сопоставления: 1/I/l/| → Ӏ, lower case, без лишних пробелов.
  static String normalizeForSearch(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      if (_isPalochkaAlias(ch)) {
        buffer.write(palochka);
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  static bool _isPalochkaAlias(String ch) {
    return ch == palochka ||
        ch == '1' ||
        ch == 'I' ||
        ch == 'i' ||
        ch == 'l' ||
        ch == '|' ||
        ch == '!' ||
        ch == '\u0406' || // Ukrainian І
        ch == '\u0456'; // і
  }

  /// Проверяет, содержит ли [haystack] подстроку [needle] с учётом палочки.
  static bool containsNormalized(String haystack, String needle) {
    if (needle.isEmpty) return true;
    return normalizeForSearch(haystack).contains(normalizeForSearch(needle));
  }

  /// Сопоставление для словаря: чеченское и/или русское поле.
  static bool matchesWordQuery({
    required String query,
    required String chechen,
    required String russian,
  }) {
    final q = query.trim();
    if (q.isEmpty) return true;
    return containsNormalized(chechen, q) || russian.toLowerCase().contains(q.toLowerCase());
  }
}
