import 'package:equatable/equatable.dart';

import 'content_metadata.dart';
import 'entry_type.dart';

/// Чистая модель записи словаря для presentation-слоя.
///
/// UI никогда не получает сырые строки из JSON — только этот тип.
/// Парсер [DictionaryParser] отвечает за классификацию, нормализацию,
/// preview и searchTokens.
class DictionaryEntry extends Equatable {
  const DictionaryEntry({
    required this.id,
    required this.type,
    required this.chechen,
    required this.russian,
    required this.preview,
    required this.searchTokens,
    this.examples = const [],
    this.category,
    this.pronunciation,
    this.sources = const [],
    this.favorite = false,
    this.frequencyTier,
    this.languageRegister,
    this.region,
    this.reviewStatus = ReviewStatus.draft,
    this.sourceRef,
    this.audioId,
    this.license,
  });

  final String id;
  final EntryType type;

  /// Нормализованный чеченский текст (полный).
  final String chechen;

  /// Нормализованный русский текст (полный).
  final String russian;

  /// Короткий preview для карточки списка. Обрезается по границе слова,
  /// никогда внутри слова. Никогда не содержит случайных "...".
  final String preview;

  /// Нижнерегистровые токены для быстрого поиска: чеченский + русский.
  final Set<String> searchTokens;

  /// Примеры употребления (пары ce/ru), если есть.
  final List<ExamplePair> examples;

  /// Категория (animals, food, ...) или null.
  final String? category;

  /// Транскрипция/произношение, если есть.
  final String? pronunciation;

  final List<String> sources;

  /// Избранное (синхронизируется с Hive через repository).
  final bool favorite;
  final FrequencyTier? frequencyTier;
  final LanguageRegister? languageRegister;
  final String? region;
  final ReviewStatus reviewStatus;
  final String? sourceRef;
  final String? audioId;
  final String? license;

  bool get isWord => type == EntryType.word;
  bool get isSentence => type == EntryType.sentence;

  DictionaryEntry copyWith({bool? favorite}) => DictionaryEntry(
    id: id,
    type: type,
    chechen: chechen,
    russian: russian,
    preview: preview,
    searchTokens: searchTokens,
    examples: examples,
    category: category,
    pronunciation: pronunciation,
    sources: sources,
    favorite: favorite ?? this.favorite,
    frequencyTier: frequencyTier,
    languageRegister: languageRegister,
    region: region,
    reviewStatus: reviewStatus,
    sourceRef: sourceRef,
    audioId: audioId,
    license: license,
  );

  @override
  List<Object?> get props => [id, favorite];
}

/// Пара пример ce/ru.
class ExamplePair extends Equatable {
  const ExamplePair({required this.chechen, required this.russian});
  final String chechen;
  final String russian;

  @override
  List<Object?> get props => [chechen, russian];
}
