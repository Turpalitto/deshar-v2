import '../entities/word_entity.dart';
import '../entities/word_progress_entity.dart';
import '../entities/learning_entities.dart';
import '../entities/culture_capsule.dart';
import '../entities/enums.dart';

abstract class DictionaryRepository {
  Future<List<WordEntity>> getAllWords();

  /// Только проверенные (curated) слова уроков — лёгкий путь без загрузки
  /// полного словаря. Для «слова дня», уроков, квизов и placement-теста.
  Future<List<WordEntity>> getCuratedWords();
  Future<WordEntity?> getWordById(String id);
  Future<List<WordEntity>> search(String query, {String? category, PartOfSpeech? pos});
  Future<List<WordEntity>> getWordsByCategory(String category);
  Future<List<WordEntity>> getWordsByIds(List<String> ids);
}

abstract class ProgressRepository {
  Future<WordProgressEntity?> getProgress(String wordId);
  Future<Map<String, WordProgressEntity>> getAllProgress();
  Future<void> saveProgress(WordProgressEntity progress);
  Future<List<WordProgressEntity>> getDueForReview();
  Future<List<String>> getFavorites();
  Future<void> toggleFavorite(String wordId);
}

abstract class LearningPathRepository {
  Future<List<LearningUnitEntity>> getUnits();
  Future<List<LessonEntity>> getLessons();
  Future<bool> isUnitUnlocked(String unitId);
}

abstract class UserRepository {
  Future<UserProfileEntity> getProfile();
  Future<void> saveProfile(UserProfileEntity profile);
}

/// Будущая интеграция: AI-преподаватель, генерация упражнений.
abstract class AiTutorRepository {
  Future<String> explainMistake({required WordEntity word, required String userAnswer});
  Future<List<String>> generatePracticeSentences({required List<WordEntity> words});
}

abstract class PdfImportRepository {
  Future<List<WordEntity>> importFromPdfBytes(List<int> bytes, {required String sourceId});
}

abstract class AudioRepository {
  Future<void> speakChechen(String text, {VoiceProfile profile = VoiceProfile.childNormal});
  Future<void> speakRussian(String text, {VoiceProfile profile = VoiceProfile.adultNormal});
}

/// UI-слой раньше импортировал data/culture_capsule_samples.dart напрямую,
/// в обход domain — три файла фич пришлось бы трогать при переходе на
/// динамический контент вместо одной реализации репозитория (аудит §1).
abstract class CultureCapsuleRepository {
  Future<List<CultureCapsule>> getAll();
  Future<CultureCapsule?> forUnit(String unitId);
  Future<CultureCapsule?> byId(String id);
}
