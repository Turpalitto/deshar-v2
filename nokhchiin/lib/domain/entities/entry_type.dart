/// Тип записи словаря.
///
/// Автоматическая классификация в [DictionaryParser.classify].
enum EntryType {
  /// Одиночное слово.
  word,
  /// Короткая фраза (2–4 слова, без глагола-сказуемого).
  phrase,
  /// Идиома — непереносимый оборот.
  idiom,
  /// Выражение / конструкция.
  expression,
  /// Полное предложение (есть сказуемое + знак препинания или > 6 слов).
  sentence,
  /// Не удалось классифицировать.
  unknown,
}

extension EntryTypeX on EntryType {
  String get label => switch (this) {
        EntryType.word => 'Слово',
        EntryType.phrase => 'Фраза',
        EntryType.idiom => 'Идиома',
        EntryType.expression => 'Выражение',
        EntryType.sentence => 'Предложение',
        EntryType.unknown => '—',
      };

  String get emoji => switch (this) {
        EntryType.word => '📖',
        EntryType.phrase => '💬',
        EntryType.idiom => '🎭',
        EntryType.expression => '✨',
        EntryType.sentence => '📝',
        EntryType.unknown => '•',
      };

  bool get isShort => this == EntryType.word || this == EntryType.unknown;
}
