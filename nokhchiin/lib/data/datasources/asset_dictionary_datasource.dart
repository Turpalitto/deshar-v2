import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/entities/enums.dart';

class AssetDictionaryDataSource {
  static const _uuid = Uuid();

  Future<List<WordEntity>> loadBundledDictionary() async {
    final words = <WordEntity>[];
    final seen = <String>{};

    // 1. Curated — highest priority
    final curatedRaw = await rootBundle.loadString('assets/data/curated_vocabulary.json');
    final curated = jsonDecode(curatedRaw) as Map<String, dynamic>;
    for (final item in curated['entries'] as List) {
      final w = _fromCurated(item as Map<String, dynamic>);
      if (seen.add(w.id)) words.add(w);
    }

    // 2. Full merged dictionary
    final dictRaw = await rootBundle.loadString('assets/data/dictionary.json');
    final dict = jsonDecode(dictRaw) as Map<String, dynamic>;
    for (final item in dict['entries'] as List) {
      final w = _fromDictionary(item as Map<String, dynamic>);
      if (seen.add(w.id)) words.add(w);
    }

    return words;
  }

  Future<List<Map<String, dynamic>>> loadLessonsJson() async {
    final raw = await rootBundle.loadString('assets/data/lessons.json');
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  Future<List<Map<String, dynamic>>> loadLearningPathJson() async {
    final raw = await rootBundle.loadString('assets/data/learning_path.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['units'] as List);
  }

  WordEntity _fromCurated(Map<String, dynamic> j) {
    final ce = (j['chechen'] as String).trim();
    return WordEntity(
      id: _id(ce),
      chechen: _capitalize(ce),
      russian: j['russian'] as String,
      pronunciation: ce,
      partOfSpeech: _guessPos(j['category'] as String?),
      category: j['category'] as String?,
      sources: List<String>.from(j['sources'] ?? ['curated']),
      emoji: j['emoji'] as String?,
      tags: ['verified'],
      hint: j['hint'] as String?,
    );
  }

  WordEntity _fromDictionary(Map<String, dynamic> j) {
    final ce = (j['chechen'] as String).trim();
    return WordEntity(
      id: _id(ce),
      chechen: ce,
      russian: j['russian'] as String,
      pronunciation: j['pronunciation'] as String?,
      category: j['category'] as String?,
      sources: List<String>.from(j['sources'] ?? ['maciev']),
      emoji: j['emoji'] as String?,
    );
  }

  String _id(String chechen) =>
      _uuid.v5(Uuid.NAMESPACE_URL, chechen.toLowerCase().replaceAll(' ', ''));

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  PartOfSpeech _guessPos(String? cat) {
    if (cat == 'verbs') return PartOfSpeech.verb;
    if (cat == 'colors' || cat == 'adjectives') return PartOfSpeech.adjective;
    if (cat == 'numbers') return PartOfSpeech.number;
    if (cat == 'greetings' || cat == 'phrases') return PartOfSpeech.phrase;
    return PartOfSpeech.noun;
  }
}
