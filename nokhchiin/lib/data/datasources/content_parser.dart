import 'dart:convert';

import '../../domain/entities/content_entities.dart';
import 'content_parse_exception.dart';

String _requireString(Map<String, dynamic> json, String field, String file) {
  final value = json[field];
  if (value is! String || value.isEmpty) {
    throw ContentParseException(
      file: file,
      key: field,
      message: 'expected non-empty String, got $value',
    );
  }
  return value;
}

int _requireInt(Map<String, dynamic> json, String field, String file) {
  final value = json[field];
  if (value is! int) {
    throw ContentParseException(
      file: file,
      key: field,
      message: 'expected int, got $value',
    );
  }
  return value;
}

List<String> _requireStringList(dynamic value, String field, String file) {
  if (value is! List) {
    throw ContentParseException(
      file: file,
      key: field,
      message: 'expected List, got $value',
    );
  }
  return value.map((e) {
    if (e is! String) {
      throw ContentParseException(
        file: file,
        key: field,
        message: 'expected List<String>, found $e',
      );
    }
    return e;
  }).toList();
}

Map<String, dynamic> decodeContentRoot(String raw, {required String file}) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw ContentParseException(
        file: file,
        key: '(root)',
        message: 'expected JSON object, got $decoded',
      );
    }
    return decoded;
  } on ContentParseException {
    rethrow;
  } catch (e) {
    throw ContentParseException(
      file: file,
      key: '(root)',
      message: 'invalid JSON: $e',
    );
  }
}

List<T> parseContentList<T>({
  required String raw,
  required String file,
  required String rootKey,
  required T Function(Map<String, dynamic> json) parseItem,
}) {
  final decoded = decodeContentRoot(raw, file: file);
  final list = decoded[rootKey];
  if (list is! List) {
    throw ContentParseException(
      file: file,
      key: rootKey,
      message: 'expected List at root key, got $list',
    );
  }
  return list.map((item) {
    if (item is! Map<String, dynamic>) {
      throw ContentParseException(
        file: file,
        key: rootKey,
        message: 'expected Map item, got $item',
      );
    }
    return parseItem(item);
  }).toList();
}

WorldEntity parseWorld(Map<String, dynamic> json, {String file = 'worlds.json'}) {
  return WorldEntity(
    id: _requireString(json, 'id', file),
    titleRu: _requireString(json, 'titleRu', file),
    titleCe: _requireString(json, 'titleCe', file),
    emoji: json['emoji'] as String?,
    gradient: _requireStringList(json['gradient'], 'gradient', file),
    unlockStars: json['unlockStars'] as int? ?? 0,
    units: _requireStringList(json['units'], 'units', file),
    subtitleRu: json['subtitleRu'] as String?,
  );
}

CollectionEntity parseCollection(Map<String, dynamic> json, {String file = 'collections.json'}) {
  return CollectionEntity(
    id: _requireString(json, 'id', file),
    titleRu: _requireString(json, 'titleRu', file),
    titleCe: _requireString(json, 'titleCe', file),
    icon: json['icon'] as String?,
    category: _requireString(json, 'category', file),
    totalCards: _requireInt(json, 'totalCards', file),
    rarity: _requireString(json, 'rarity', file),
  );
}

ChestEntity parseChest(Map<String, dynamic> json, {String file = 'collections.json'}) {
  return ChestEntity(
    id: _requireString(json, 'id', file),
    titleRu: _requireString(json, 'titleRu', file),
    starsRequired: json['starsRequired'] as int? ?? 0,
    cooldownHours: json['cooldownHours'] as int? ?? 0,
  );
}

StoryDialogueLine parseStoryDialogue(Map<String, dynamic> json, {String file = 'stories.json'}) {
  return StoryDialogueLine(
    speaker: _requireString(json, 'speaker', file),
    chechen: _requireString(json, 'chechen', file),
    russian: _requireString(json, 'russian', file),
  );
}

StoryPanelEntity parseStoryPanel(Map<String, dynamic> json, {String file = 'stories.json'}) {
  final dialogueRaw = json['dialogue'];
  final dialogue = <StoryDialogueLine>[];
  if (dialogueRaw is List) {
    for (final item in dialogueRaw) {
      if (item is Map<String, dynamic>) {
        dialogue.add(parseStoryDialogue(item, file: file));
      }
    }
  }
  return StoryPanelEntity(
    imageKey: _requireString(json, 'imageKey', file),
    narrationRu: _requireString(json, 'narrationRu', file),
    dialogue: dialogue,
  );
}

StoryQuizEntity parseStoryQuiz(Map<String, dynamic> json, {String file = 'stories.json'}) {
  return StoryQuizEntity(
    question: _requireString(json, 'question', file),
    answer: _requireString(json, 'answer', file),
    options: _requireStringList(json['options'], 'options', file),
  );
}

StoryEntity parseStory(Map<String, dynamic> json, {String file = 'stories.json'}) {
  final panelsRaw = json['panels'];
  final panels = <StoryPanelEntity>[];
  if (panelsRaw is List) {
    for (final item in panelsRaw) {
      if (item is Map<String, dynamic>) {
        panels.add(parseStoryPanel(item, file: file));
      }
    }
  }

  final quizRaw = json['quiz'];
  final quiz = <StoryQuizEntity>[];
  if (quizRaw is List) {
    for (final item in quizRaw) {
      if (item is Map<String, dynamic>) {
        quiz.add(parseStoryQuiz(item, file: file));
      }
    }
  }

  return StoryEntity(
    id: _requireString(json, 'id', file),
    titleRu: _requireString(json, 'titleRu', file),
    titleCe: _requireString(json, 'titleCe', file),
    unitId: _requireString(json, 'unitId', file),
    requiredMastery: json['requiredMastery'] as int? ?? 50,
    emoji: json['emoji'] as String?,
    panels: panels,
    quiz: quiz,
  );
}

BossEntity parseBoss(Map<String, dynamic> json, {String file = 'bosses.json'}) {
  return BossEntity(
    id: _requireString(json, 'id', file),
    unitId: _requireString(json, 'unitId', file),
    titleRu: _requireString(json, 'titleRu', file),
    titleCe: _requireString(json, 'titleCe', file),
    emoji: json['emoji'] as String?,
    questionsCount: _requireInt(json, 'questionsCount', file),
    timeLimitSec: _requireInt(json, 'timeLimitSec', file),
    passScore: _requireInt(json, 'passScore', file),
    rewardStars: _requireInt(json, 'rewardStars', file),
    rewardXp: _requireInt(json, 'rewardXp', file),
  );
}

List<WorldEntity> parseWorlds(String raw) => parseContentList(
      raw: raw,
      file: 'worlds.json',
      rootKey: 'worlds',
      parseItem: parseWorld,
    );

List<CollectionEntity> parseCollections(String raw) => parseContentList(
      raw: raw,
      file: 'collections.json',
      rootKey: 'collections',
      parseItem: parseCollection,
    );

List<ChestEntity> parseChests(String raw) => parseContentList(
      raw: raw,
      file: 'collections.json',
      rootKey: 'chests',
      parseItem: parseChest,
    );

List<StoryEntity> parseStories(String raw) => parseContentList(
      raw: raw,
      file: 'stories.json',
      rootKey: 'stories',
      parseItem: parseStory,
    );

List<BossEntity> parseBosses(String raw) => parseContentList(
      raw: raw,
      file: 'bosses.json',
      rootKey: 'bosses',
      parseItem: parseBoss,
    );
