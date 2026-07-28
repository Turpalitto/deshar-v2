import 'package:equatable/equatable.dart';
import 'content_metadata.dart';
import 'enums.dart';

/// Единая сущность слова — центр всей платформы.
class WordEntity extends Equatable {
  const WordEntity({
    required this.id,
    required this.chechen,
    required this.russian,
    this.pronunciation,
    this.partOfSpeech = PartOfSpeech.other,
    this.category,
    this.exampleCe,
    this.exampleRu,
    this.synonyms = const [],
    this.sources = const [],
    this.emoji,
    this.illustrationKey,
    this.audioCeUrl,
    this.audioRuUrl,
    this.tags = const [],
    this.hint,
    this.nounClass,
    this.frequencyTier,
    this.languageRegister,
    this.region,
    this.reviewStatus = ReviewStatus.draft,
    this.sourceRef,
    this.audioId,
    this.license,
  });

  final String id;
  final String chechen;
  final String russian;
  final String? pronunciation;
  final PartOfSpeech partOfSpeech;
  final String? category;
  final String? exampleCe;
  final String? exampleRu;
  final List<String> synonyms;
  final List<String> sources;
  final String? emoji;
  final String? illustrationKey;
  final String? audioCeUrl;
  final String? audioRuUrl;
  final List<String> tags;
  final String? hint;
  final NounClass? nounClass;
  final FrequencyTier? frequencyTier;
  final LanguageRegister? languageRegister;
  final String? region;
  final ReviewStatus reviewStatus;
  final String? sourceRef;
  final String? audioId;
  final String? license;

  bool get isPhrase =>
      chechen.contains(' ') || partOfSpeech == PartOfSpeech.phrase;

  WordEntity copyWith({
    String? chechen,
    String? russian,
    String? pronunciation,
    PartOfSpeech? partOfSpeech,
    String? category,
    String? exampleCe,
    String? exampleRu,
    List<String>? synonyms,
    List<String>? sources,
    String? emoji,
    String? illustrationKey,
    String? audioCeUrl,
    String? audioRuUrl,
    List<String>? tags,
    String? hint,
    NounClass? nounClass,
    FrequencyTier? frequencyTier,
    LanguageRegister? languageRegister,
    String? region,
    ReviewStatus? reviewStatus,
    String? sourceRef,
    String? audioId,
    String? license,
  }) {
    return WordEntity(
      id: id,
      chechen: chechen ?? this.chechen,
      russian: russian ?? this.russian,
      pronunciation: pronunciation ?? this.pronunciation,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      category: category ?? this.category,
      exampleCe: exampleCe ?? this.exampleCe,
      exampleRu: exampleRu ?? this.exampleRu,
      synonyms: synonyms ?? this.synonyms,
      sources: sources ?? this.sources,
      emoji: emoji ?? this.emoji,
      illustrationKey: illustrationKey ?? this.illustrationKey,
      audioCeUrl: audioCeUrl ?? this.audioCeUrl,
      audioRuUrl: audioRuUrl ?? this.audioRuUrl,
      tags: tags ?? this.tags,
      hint: hint ?? this.hint,
      nounClass: nounClass ?? this.nounClass,
      frequencyTier: frequencyTier ?? this.frequencyTier,
      languageRegister: languageRegister ?? this.languageRegister,
      region: region ?? this.region,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      sourceRef: sourceRef ?? this.sourceRef,
      audioId: audioId ?? this.audioId,
      license: license ?? this.license,
    );
  }

  @override
  List<Object?> get props => [id];
}
