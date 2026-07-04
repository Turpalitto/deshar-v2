import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/word_progress_entity.dart';
import '../../domain/entities/enums.dart';

class LocalProgressDataSource {
  static const boxName = 'word_progress_v1';

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Map>(boxName);
    }
  }

  Box<Map> get _box => Hive.box<Map>(boxName);

  Future<Map<String, WordProgressEntity>> getAll() async {
    final result = <String, WordProgressEntity>{};
    for (final key in _box.keys) {
      final map = _box.get(key);
      if (map != null) result[key] = _fromMap(key, map);
    }
    return result;
  }

  Future<WordProgressEntity?> get(String wordId) async {
    final map = _box.get(wordId);
    if (map == null) return null;
    return _fromMap(wordId, map);
  }

  Future<void> save(WordProgressEntity p) async {
    await _box.put(p.wordId, _toMap(p));
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
    if (!Hive.isBoxOpen(boxName)) await Hive.openBox<Map>(boxName);
  }

  Future<Map<String, dynamic>?> get() async {
    final box = Hive.box<Map>(boxName);
    final data = box.get('profile');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> save(Map<String, dynamic> data) async {
    await Hive.box<Map>(boxName).put('profile', data);
  }
}
