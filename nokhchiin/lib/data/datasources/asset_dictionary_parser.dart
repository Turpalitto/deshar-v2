import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/content_metadata.dart';
import '../../domain/entities/word_entity.dart';
import '../../core/utils/dictionary_labels.dart';

const _uuid = Uuid();

/// Лёгкий парсинг ТОЛЬКО curated-словаря (~330 записей, ~77 КБ) — без
/// полного dictionary.json (23 МБ, 134k записей). Используется везде, где
/// нужны слова уроков/категорий: на web `compute()` выполняется в главном
/// потоке, и полный парсинг замораживал UI на секунды при первом уроке,
/// квизе, placement-тесте и «слове дня».
/// Парсинг lessons.json — primary source для слов уроков/игр.
({Map<String, List<WordEntity>> byCategory, Map<String, WordEntity> byId})
parseLessonsWords(String lessonsRaw) {
  final lessons = jsonDecode(lessonsRaw) as List;
  return parseLessonsFromMaps(lessons.cast<Map<String, dynamic>>());
}

({Map<String, List<WordEntity>> byCategory, Map<String, WordEntity> byId})
parseLessonsFromMaps(List<Map<String, dynamic>> lessons) {
  final byCategory = <String, List<WordEntity>>{};
  final byId = <String, WordEntity>{};
  for (final map in lessons) {
    final categoryId = map['id'] as String;
    final words = <WordEntity>[];
    for (final item in map['words'] as List) {
      final w = _fromLesson(item as Map<String, dynamic>, categoryId);
      if (w.chechen.isEmpty || w.russian.isEmpty) continue;
      words.add(w);
      byId[w.id] = w;
    }
    byCategory[categoryId] = words;
  }
  return (byCategory: byCategory, byId: byId);
}

List<WordEntity> parseCuratedWords(String curatedRaw) {
  final words = <WordEntity>[];
  final seen = <String>{};
  final curated = jsonDecode(curatedRaw) as Map<String, dynamic>;
  for (final item in curated['entries'] as List) {
    final w = _fromCurated(item as Map<String, dynamic>);
    if (w.chechen.isEmpty || w.russian.isEmpty) continue;
    if (seen.add(w.id)) words.add(w);
  }
  return words;
}

/// Top-level для [compute]: парсинг JSON словаря вне UI isolate.
List<WordEntity> parseBundledDictionaryIsolate(
  Map<String, String> rawJsonByKey,
) {
  final words = <WordEntity>[];
  final seen = <String>{};

  final curated = jsonDecode(rawJsonByKey['curated']!) as Map<String, dynamic>;
  for (final item in curated['entries'] as List) {
    final w = _fromCurated(item as Map<String, dynamic>);
    if (w.chechen.isEmpty || w.russian.isEmpty) continue;
    if (seen.add(w.id)) words.add(w);
  }

  final lessonsRaw = rawJsonByKey['lessons'];
  if (lessonsRaw != null && lessonsRaw.isNotEmpty) {
    final parsed = parseLessonsWords(lessonsRaw);
    for (final list in parsed.byCategory.values) {
      for (final w in list) {
        if (seen.add(w.id)) words.add(w);
      }
    }
  }

  final dict = jsonDecode(rawJsonByKey['dictionary']!) as Map<String, dynamic>;
  for (final item in dict['entries'] as List) {
    final w = _fromDictionary(item as Map<String, dynamic>);
    if (w.chechen.isEmpty || w.russian.isEmpty) continue;
    if (seen.add(w.id)) words.add(w);
  }

  return words;
}

WordEntity _fromLesson(Map<String, dynamic> j, String category) {
  final ce = ((j['chechen'] as String?) ?? '').trim();
  final ru = (j['russian'] as String?) ?? '';
  final pronunciation = (j['pronunciation'] as String?)?.trim();
  return WordEntity(
    id: _id(ce, ru),
    chechen: _capitalize(ce),
    russian: ru,
    pronunciation: pronunciation?.isNotEmpty == true
        ? pronunciation
        : DictionaryLabels.displayTranscription(_capitalize(ce), ce),
    partOfSpeech: _guessPos(category),
    category: category,
    sources: const ['lessons'],
    emoji: j['emoji'] as String?,
    tags: const [],
    hint: j['hint'] as String?,
    frequencyTier: FrequencyTier.fromJson(j['frequencyTier']),
    languageRegister: LanguageRegister.fromJson(j['register']),
    region: j['region'] as String?,
    reviewStatus: ReviewStatus.fromJson(j['reviewStatus']),
    sourceRef: j['sourceRef'] as String?,
    exampleCe: j['exampleCe'] as String?,
    exampleRu: j['exampleRu'] as String?,
    audioId: j['audioId'] as String?,
    license: j['license'] as String?,
  );
}

WordEntity _fromCurated(Map<String, dynamic> j) {
  final ce = ((j['chechen'] as String?) ?? '').trim();
  final ru = (j['russian'] as String?) ?? '';
  return WordEntity(
    id: _id(ce, ru),
    chechen: _capitalize(ce),
    russian: ru,
    pronunciation: DictionaryLabels.displayTranscription(_capitalize(ce), ce),
    partOfSpeech: _guessPos(j['category'] as String?),
    category: j['category'] as String?,
    sources: List<String>.from(j['sources'] ?? ['curated']),
    emoji: j['emoji'] as String?,
    tags: const [],
    hint: j['hint'] as String?,
    nounClass: NounClass.fromCode(j['nounClass'] as String?),
    frequencyTier: FrequencyTier.fromJson(j['frequencyTier']),
    languageRegister: LanguageRegister.fromJson(j['register']),
    region: j['region'] as String?,
    reviewStatus: ReviewStatus.fromJson(j['reviewStatus']),
    sourceRef: j['sourceRef'] as String?,
    exampleCe: j['exampleCe'] as String?,
    exampleRu: j['exampleRu'] as String?,
    audioId: j['audioId'] as String?,
    license: j['license'] as String?,
  );
}

WordEntity _fromDictionary(Map<String, dynamic> j) {
  final ce = ((j['chechen'] as String?) ?? '').trim();
  final ru = (j['russian'] as String?) ?? '';
  final sources = List<String>.from(j['sources'] ?? ['maciev']);
  return WordEntity(
    id: _id(ce, ru),
    chechen: ce,
    russian: ru,
    pronunciation: DictionaryLabels.displayTranscription(
      ce,
      j['pronunciation'] as String?,
    ),
    category: j['category'] as String?,
    sources: sources,
    emoji: j['emoji'] as String?,
    nounClass: NounClass.fromCode(j['nounClass'] as String?),
    frequencyTier: FrequencyTier.fromJson(j['frequencyTier']),
    languageRegister: LanguageRegister.fromJson(j['register']),
    region: j['region'] as String?,
    reviewStatus: ReviewStatus.fromJson(j['reviewStatus']),
    sourceRef: j['sourceRef'] as String?,
    exampleCe: j['exampleCe'] as String?,
    exampleRu: j['exampleRu'] as String?,
    audioId: j['audioId'] as String?,
    license: j['license'] as String?,
  );
}

String _id(String chechen, String russian) => _uuid.v5(
  Namespace.url.value,
  '${chechen.toLowerCase().replaceAll(' ', '')}|${russian.toLowerCase().trim()}',
);

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

PartOfSpeech _guessPos(String? cat) {
  if (cat == 'verbs') return PartOfSpeech.verb;
  if (cat == 'colors' || cat == 'adjectives') return PartOfSpeech.adjective;
  if (cat == 'numbers') return PartOfSpeech.number;
  if (cat == 'greetings' || cat == 'phrases') return PartOfSpeech.phrase;
  return PartOfSpeech.noun;
}
