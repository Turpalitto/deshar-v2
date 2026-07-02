import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/repositories.dart';

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
