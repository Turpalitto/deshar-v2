import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/word_progress_entity.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/deck_entity.dart';
import '../../core/utils/app_logger.dart';

class LocalProgressDataSource {
  static const boxName = 'word_progress_v1';

  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox<Map>(boxName);
      }
    } catch (e, st) {
      AppLogger.error('Failed to open progress box', error: e, stackTrace: st);
      rethrow;
    }
  }

  Box<Map> get _box => Hive.box<Map>(boxName);

  Future<Map<String, WordProgressEntity>> getAll() async {
    final result = <String, WordProgressEntity>{};
    for (final key in _box.keys) {
      final map = _box.get(key);
      if (map == null) continue;
      try {
        result[key] = _fromMap(key, map);
      } catch (e, st) {
        // Пропускаем одну битую запись, не роняя весь прогресс —
        // раньше одна запись с плохим DateTime/типом очищала весь
        // прогресс пользователя (аудит local_storage).
        AppLogger.warn(
          'Skipping corrupt progress entry $key',
          error: e,
          stackTrace: st,
        );
      }
    }
    return result;
  }

  Future<WordProgressEntity?> get(String wordId) async {
    try {
      final map = _box.get(wordId);
      if (map == null) return null;
      return _fromMap(wordId, map);
    } catch (e, st) {
      AppLogger.error(
        'Failed to read progress for $wordId',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<void> save(WordProgressEntity p) async {
    try {
      await _box.put(p.wordId, _toMap(p));
    } catch (e, st) {
      AppLogger.error(
        'Failed to save progress for ${p.wordId}',
        error: e,
        stackTrace: st,
      );
    }
  }

  Map<String, dynamic> _toMap(WordProgressEntity p) => {
    'mastery': p.mastery.value,
    'easeFactor': p.easeFactor,
    'intervalDays': p.intervalDays,
    'repetitions': p.repetitions,
    'nextReviewAt': p.nextReviewAt?.toIso8601String(),
    'lastReviewedAt': p.lastReviewedAt?.toIso8601String(),
    'lastSuccessfulReviewAt': p.lastSuccessfulReviewAt?.toIso8601String(),
    'successfulReviewDays': p.successfulReviewDays,
    'correctStreak': p.correctStreak,
    'wrongCount': p.wrongCount,
    'isFavorite': p.isFavorite,
    'seededFromPlacement': p.seededFromPlacement,
    'deckIds': p.deckIds.toList()..sort(),
  };

  WordProgressEntity _fromMap(String id, Map map) {
    final mastery = MasteryLevel.fromValue(map['mastery'] as int? ?? 0);
    final repetitions = map['repetitions'] as int? ?? 0;
    final lastReviewedAt = _parseDate(map['lastReviewedAt']);
    final migratedSuccessfulDays =
        map['successfulReviewDays'] as int? ??
        (mastery.isMastered ? 3 : repetitions.clamp(0, 2));

    return WordProgressEntity(
      wordId: id,
      mastery: mastery,
      easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: map['intervalDays'] as int? ?? 0,
      repetitions: repetitions,
      nextReviewAt: _parseDate(map['nextReviewAt']),
      lastReviewedAt: lastReviewedAt,
      lastSuccessfulReviewAt:
          _parseDate(map['lastSuccessfulReviewAt']) ??
          (repetitions > 0 ? lastReviewedAt : null),
      successfulReviewDays: migratedSuccessfulDays,
      correctStreak: map['correctStreak'] as int? ?? 0,
      wrongCount: map['wrongCount'] as int? ?? 0,
      isFavorite: map['isFavorite'] as bool? ?? false,
      seededFromPlacement: map['seededFromPlacement'] as bool? ?? false,
      deckIds: {
        for (final id in (map['deckIds'] as List? ?? const []))
          if (id is String && id.isNotEmpty) id,
      },
    );
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class LocalDeckDataSource {
  static const boxName = 'decks_v1';

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Map>(boxName);
    }
  }

  Box<Map> get _box => Hive.box<Map>(boxName);

  Future<List<DeckEntity>> getAll() async {
    final decks = <DeckEntity>[];
    for (final value in _box.values) {
      final id = value['id'];
      final title = value['title'];
      if (id is! String || title is! String || title.trim().isEmpty) continue;
      decks.add(
        DeckEntity(
          id: id,
          title: title,
          isSystem: false,
          createdAt: DateTime.tryParse(value['createdAt']?.toString() ?? ''),
        ),
      );
    }
    decks.sort(
      (a, b) =>
          (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)),
    );
    return decks;
  }

  Future<void> save(DeckEntity deck) async {
    if (deck.isSystem) return;
    await _box.put(deck.id, {
      'id': deck.id,
      'title': deck.title,
      'createdAt': deck.createdAt?.toIso8601String(),
    });
  }

  Future<void> delete(String deckId) => _box.delete(deckId);
}

class LocalUserDataSource {
  static const boxName = 'user_profile_v1';

  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(boxName)) await Hive.openBox<Map>(boxName);
    } catch (e, st) {
      AppLogger.error('Failed to open user box', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> get() async {
    try {
      final box = Hive.box<Map>(boxName);
      final data = box.get('profile');
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e, st) {
      AppLogger.error('Failed to read user profile', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    try {
      await Hive.box<Map>(boxName).put('profile', data);
    } catch (e, st) {
      AppLogger.error('Failed to save user profile', error: e, stackTrace: st);
    }
  }
}
