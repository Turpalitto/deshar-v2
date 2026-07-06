import '../entities/enums.dart';
import '../entities/word_progress_entity.dart';
import '../repositories/repositories.dart';

/// Проставляет освоенность слов юнита по результату placement-теста при
/// онбординге взрослых — чтобы пользователь, уже знающий часть базовой
/// лексики, не начинал путь обучения с нуля.
///
/// `repetitions: 0` — намеренно: слова не должны разом попасть в очередь
/// SRS-повторения (см. `ProgressRepository.getDueForReview`), а просто
/// засчитаться как уже освоенные для прогресса юнита.
class SeedUnitMasteryFromPlacementUseCase {
  SeedUnitMasteryFromPlacementUseCase(this._progressRepo, this._dictionaryRepo);

  final ProgressRepository _progressRepo;
  final DictionaryRepository _dictionaryRepo;

  Future<void> call(String unitId) async {
    final words = await _dictionaryRepo.getWordsByCategory(unitId);
    for (final w in words) {
      await _progressRepo.saveProgress(WordProgressEntity(
        wordId: w.id,
        mastery: MasteryLevel.mastered,
        repetitions: 0,
        seededFromPlacement: true,
      ));
    }
  }
}
