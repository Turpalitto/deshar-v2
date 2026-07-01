import '../../domain/entities/word_entity.dart';
import '../../domain/entities/word_progress_entity.dart';
import '../../domain/entities/learning_entities.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/asset_dictionary_datasource.dart';
import '../datasources/local_storage_datasource.dart';

class DictionaryRepositoryImpl implements DictionaryRepository {
  DictionaryRepositoryImpl(this._assets);

  final AssetDictionaryDataSource _assets;
  List<WordEntity>? _cache;

  Future<List<WordEntity>> _load() async {
    _cache ??= await _assets.loadBundledDictionary();
    return _cache!;
  }

  @override
  Future<List<WordEntity>> getAllWords() => _load();

  @override
  Future<WordEntity?> getWordById(String id) async {
    final all = await _load();
    try {
      return all.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WordEntity>> search(String query,
      {String? category, PartOfSpeech? pos}) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    final all = await _load();
    return all.where((w) {
      if (category != null && w.category != category) return false;
      if (pos != null && w.partOfSpeech != pos) return false;
      return w.chechen.toLowerCase().contains(q) ||
          w.russian.toLowerCase().contains(q);
    }).take(80).toList();
  }

  @override
  Future<List<WordEntity>> getWordsByCategory(String category) async {
    final all = await _load();
    return all.where((w) => w.category == category).toList();
  }

  @override
  Future<List<WordEntity>> getWordsByIds(List<String> ids) async {
    final all = await _load();
    final set = ids.toSet();
    return all.where((w) => set.contains(w.id)).toList();
  }
}

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._local);

  final LocalProgressDataSource _local;

  @override
  Future<WordProgressEntity?> getProgress(String wordId) => _local.get(wordId);

  @override
  Future<Map<String, WordProgressEntity>> getAllProgress() => _local.getAll();

  @override
  Future<void> saveProgress(WordProgressEntity progress) =>
      _local.save(progress);

  @override
  Future<List<WordProgressEntity>> getDueForReview() async {
    final all = await _local.getAll();
    return all.values.where((p) => p.needsReview).toList();
  }

  @override
  Future<List<String>> getFavorites() async {
    final all = await _local.getAll();
    return all.values.where((p) => p.isFavorite).map((p) => p.wordId).toList();
  }

  @override
  Future<void> toggleFavorite(String wordId) async {
    final p = await _local.get(wordId) ?? WordProgressEntity(wordId: wordId);
    await _local.save(p.copyWith(isFavorite: !p.isFavorite));
  }
}

class LearningPathRepositoryImpl implements LearningPathRepository {
  LearningPathRepositoryImpl(this._assets, this._dictionary);

  final AssetDictionaryDataSource _assets;
  final DictionaryRepository _dictionary;

  @override
  Future<List<LearningUnitEntity>> getUnits() async {
    final path = await _assets.loadLearningPathJson();
    final units = <LearningUnitEntity>[];
    for (final u in path) {
      final id = u['id'] as String;
      final words = await _dictionary.getWordsByCategory(id);
      units.add(LearningUnitEntity(
        id: id,
        order: u['order'] as int,
        titleRu: u['titleRu'] as String,
        titleCe: u['titleCe'] as String,
        icon: u['icon'] as String,
        requiredMastery: u['requiredMastery'] as int,
        wordIds: words.map((w) => w.id).toList(),
      ));
    }
    units.sort((a, b) => a.order.compareTo(b.order));
    return units;
  }

  @override
  Future<List<LessonEntity>> getLessons() async {
    final raw = await _assets.loadLessonsJson();
    return raw.map((l) {
      final words = (l['words'] as List).cast<Map<String, dynamic>>();
      return LessonEntity(
        id: l['id'] as String,
        title: l['title'] as String,
        chechenTitle: l['chechenTitle'] as String,
        icon: l['icon'] as String? ?? '📖',
        colorHex: '#1A73E8',
        wordIds: words.map((w) {
          final ce = (w['chechen'] as String).toLowerCase().replaceAll(' ', '');
          return ce; // matched at runtime by chechen text
        }).toList(),
      );
    }).toList();
  }

  @override
  Future<bool> isUnitUnlocked(String unitId) async {
    final units = await getUnits();
    final unit = units.firstWhere((u) => u.id == unitId);
    if (unit.order == 1) return true;
    return false; // computed in provider with use case
  }
}

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._local);

  final LocalUserDataSource _local;

  @override
  Future<UserProfileEntity> getProfile() async {
    final data = await _local.get();
    if (data == null) return const UserProfileEntity();
    return UserProfileEntity(
      mode: AppMode.values[data['mode'] as int? ?? 0],
      ageGroup: KidsAgeGroup.values[data['ageGroup'] as int? ?? 1],
      xp: data['xp'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      streakDays: data['streakDays'] as int? ?? 0,
      stars: data['stars'] as int? ?? 0,
      coins: data['coins'] as int? ?? data['stars'] as int? ?? 0,
      dailyGoalMinutes: data['dailyGoalMinutes'] as int? ?? 10,
      dailyGoalWords: data['dailyGoalWords'] as int? ?? 5,
      todayMinutes: data['todayMinutes'] as int? ?? 0,
      wordsLearnedToday: data['wordsLearnedToday'] as int? ?? 0,
      avatarId: data['avatarId'] as String? ?? 'fox_default',
      currentWorldId: data['currentWorldId'] as String? ?? 'meadow',
      unlockedWorlds: (data['unlockedWorlds'] as List?)?.cast<String>() ?? const ['meadow'],
      achievements: (data['achievements'] as List?)?.cast<String>() ?? const [],
      lastActiveDate: data['lastActiveDate'] as String?,
      dailyGiftClaimed: data['dailyGiftClaimed'] as bool? ?? false,
      weeklyXp: (data['weeklyXp'] as List?)?.cast<int>() ?? const [0, 0, 0, 0, 0, 0, 0],
      isPremium: data['isPremium'] as bool? ?? false,
      lessonsCompletedTotal: data['lessonsCompletedTotal'] as int? ?? 0,
      reviewsDoneToday: data['reviewsDoneToday'] as int? ?? 0,
      seenCultureCapsules: (data['seenCultureCapsules'] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  Future<void> saveProfile(UserProfileEntity profile) async {
    await _local.save({
      'mode': profile.mode.index,
      'ageGroup': profile.ageGroup.index,
      'xp': profile.xp,
      'level': profile.level,
      'streakDays': profile.streakDays,
      'stars': profile.stars,
      'coins': profile.coins,
      'dailyGoalMinutes': profile.dailyGoalMinutes,
      'dailyGoalWords': profile.dailyGoalWords,
      'todayMinutes': profile.todayMinutes,
      'wordsLearnedToday': profile.wordsLearnedToday,
      'avatarId': profile.avatarId,
      'currentWorldId': profile.currentWorldId,
      'unlockedWorlds': profile.unlockedWorlds,
      'achievements': profile.achievements,
      'lastActiveDate': profile.lastActiveDate,
      'dailyGiftClaimed': profile.dailyGiftClaimed,
      'weeklyXp': profile.weeklyXp,
      'isPremium': profile.isPremium,
      'lessonsCompletedTotal': profile.lessonsCompletedTotal,
      'reviewsDoneToday': profile.reviewsDoneToday,
      'seenCultureCapsules': profile.seenCultureCapsules,
    });
  }
}

/// Заглушка для будущего AI — архитектура готова.
class AiTutorRepositoryStub implements AiTutorRepository {
  @override
  Future<String> explainMistake(
          {required WordEntity word, required String userAnswer}) async =>
      'Правильный ответ: ${word.chechen} — ${word.russian}. '
      'Попробуй повторить вслух три раза.';

  @override
  Future<List<String>> generatePracticeSentences(
          {required List<WordEntity> words}) async =>
      words
          .take(3)
          .map((w) => '${w.chechen} — ${w.russian}.')
          .toList();
}

class PdfImportRepositoryStub implements PdfImportRepository {
  @override
  Future<List<WordEntity>> importFromPdfBytes(List<int> bytes,
      {required String sourceId}) async {
    // Реальный импорт через tools/build_dictionary.py → assets
    throw UnimplementedError(
      'Используйте tools/build_dictionary.py для импорта PDF, затем обновите assets/data/',
    );
  }
}
