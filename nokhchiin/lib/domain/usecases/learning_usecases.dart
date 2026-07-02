import '../entities/word_entity.dart';
import '../entities/word_progress_entity.dart';
import '../entities/learning_entities.dart';
import '../entities/enums.dart';
import '../repositories/repositories.dart';
import '../services/spaced_repetition_engine.dart';

class ReviewWordUseCase {
  ReviewWordUseCase(this._progressRepo, [this._srs = const SpacedRepetitionEngine()]);

  final ProgressRepository _progressRepo;
  final SpacedRepetitionEngine _srs;

  Future<WordProgressEntity> call(String wordId, int quality) async {
    final existing = await _progressRepo.getProgress(wordId) ??
        WordProgressEntity(wordId: wordId);
    final updated = _srs.review(existing, quality);
    await _progressRepo.saveProgress(updated);
    return updated;
  }
}

class GetDueWordsUseCase {
  GetDueWordsUseCase(this._progressRepo, this._dictionaryRepo);

  final ProgressRepository _progressRepo;
  final DictionaryRepository _dictionaryRepo;

  Future<List<WordEntity>> call({int limit = 20}) async {
    final due = await _progressRepo.getDueForReview();
    due.sort((a, b) =>
        (a.nextReviewAt ?? DateTime(2000)).compareTo(b.nextReviewAt ?? DateTime(2000)));
    final ids = due.take(limit).map((e) => e.wordId).toList();
    return _dictionaryRepo.getWordsByIds(ids);
  }
}

class CanUnlockUnitUseCase {
  CanUnlockUnitUseCase(LearningPathRepository _, this._progressRepo, this._dictionaryRepo);

  final ProgressRepository _progressRepo;
  final DictionaryRepository _dictionaryRepo;

  Future<bool> call(LearningUnitEntity unit, LearningUnitEntity? previousUnit) async {
    if (unit.order == 1) return true;
    if (previousUnit == null) return false;
    final prevWords = await _dictionaryRepo.getWordsByCategory(previousUnit.id);
    if (prevWords.isEmpty) return true;
    final progress = await _progressRepo.getAllProgress();
    var mastered = 0;
    for (final w in prevWords) {
      final p = progress[w.id];
      if (p != null && p.mastery.isMastered) mastered++;
    }
    final pct = (mastered / prevWords.length * 100).round();
    return pct >= unit.requiredMastery;
  }
}

class UnitMasteryPercentUseCase {
  UnitMasteryPercentUseCase(this._progressRepo, this._dictionaryRepo);

  final ProgressRepository _progressRepo;
  final DictionaryRepository _dictionaryRepo;

  Future<int> call(String categoryId) async {
    final words = await _dictionaryRepo.getWordsByCategory(categoryId);
    if (words.isEmpty) return 0;
    final progress = await _progressRepo.getAllProgress();
    var score = 0;
    for (final w in words) {
      final p = progress[w.id];
      if (p != null) score += p.mastery.value;
    }
    final max = words.length * MasteryLevel.mastered.value;
    return ((score / max) * 100).round().clamp(0, 100);
  }
}
