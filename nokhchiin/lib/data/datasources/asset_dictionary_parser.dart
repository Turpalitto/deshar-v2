import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/word_entity.dart';
import '../../core/utils/dictionary_labels.dart';

const _uuid = Uuid();

/// Top-level для [compute]: парсинг JSON словаря вне UI isolate.
List<WordEntity> parseBundledDictionaryIsolate(Map<String, String> rawJsonByKey) {
  final words = <WordEntity>[];
  final seen = <String>{};

  final curated = jsonDecode(rawJsonByKey['curated']!) as Map<String, dynamic>;
  for (final item in curated['entries'] as List) {
    final w = _fromCurated(item as Map<String, dynamic>);
    if (w.chechen.isEmpty || w.russian.isEmpty) continue;
    if (seen.add(w.id)) words.add(w);
  }

  final dict = jsonDecode(rawJsonByKey['dictionary']!) as Map<String, dynamic>;
  for (final item in dict['entries'] as List) {
    final w = _fromDictionary(item as Map<String, dynamic>);
    if (w.chechen.isEmpty || w.russian.isEmpty) continue;
    if (seen.add(w.id)) words.add(w);
  }

  return words;
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
    tags: const ['verified'],
    hint: j['hint'] as String?,
    nounClass: NounClass.fromCode(j['nounClass'] as String?),
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
  );
}

String _id(String chechen, String russian) => _uuid.v5(
      Uuid.NAMESPACE_URL,
      '${chechen.toLowerCase().replaceAll(' ', '')}|${russian.toLowerCase().trim()}',
    );

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

PartOfSpeech _guessPos(String? cat) {
  if (cat == 'verbs') return PartOfSpeech.verb;
  if (cat == 'colors' || cat == 'adjectives') return PartOfSpeech.adjective;
  if (cat == 'numbers') return PartOfSpeech.number;
  if (cat == 'greetings' || cat == 'phrases') return PartOfSpeech.phrase;
  return PartOfSpeech.noun;
}
