import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/word_progress_entity.dart';
import '../../domain/entities/enums.dart';
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
    try {
      final result = <String, WordProgressEntity>{};
      for (final key in _box.keys) {
        final map = _box.get(key);
        if (map != null) result[key] = _fromMap(key, map);
      }
      return result;
    } catch (e, st) {
      AppLogger.error('Failed to read all progress', error: e, stackTrace: st);
      return {};
    }
  }

  Future<WordProgressEntity?> get(String wordId) async {
    try {
      final map = _box.get(wordId);
      if (map == null) return null;
      return _fromMap(wordId, map);
    } catch (e, st) {
      AppLogger.error('Failed to read progress for $wordId', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> save(WordProgressEntity p) async {
    try {
      await _box.put(p.wordId, _toMap(p));
    } catch (e, st) {
      AppLogger.error('Failed to save progress for ${p.wordId}', error: e, stackTrace: st);
    }
  }

  Map<String, dynamic> _toMap(WordProgressEntity p) => {
        'mastery': p.mastery.value,
        'easeFactor': p.easeFactor,
        'intervalDays': p.intervalDays,
        'repetitions': p.repetitions,
        'nextReviewAt': p.nextReviewAt?.toIso8601String(),
        'lastReviewedAt': p.lastReviewedAt?.toIso8601String(),
        'correctStreak': p.correctStreak,
        'wrongCount': p.wrongCount,
        'isFavorite': p.isFavorite,
      };

  WordProgressEntity _fromMap(String id, Map map) => WordProgressEntity(
        wordId: id,
        mastery: MasteryLevel.fromValue(map['mastery'] as int? ?? 0),
        easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
        intervalDays: map['intervalDays'] as int? ?? 0,
        repetitions: map['repetitions'] as int? ?? 0,
        nextReviewAt: map['nextReviewAt'] != null
            ? DateTime.parse(map['nextReviewAt'] as String)
            : null,
        lastReviewedAt: map['lastReviewedAt'] != null
            ? DateTime.parse(map['lastReviewedAt'] as String)
            : null,
        correctStreak: map['correctStreak'] as int? ?? 0,
        wrongCount: map['wrongCount'] as int? ?? 0,
        isFavorite: map['isFavorite'] as bool? ?? false,
      );
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
