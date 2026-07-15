import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/repositories.dart';

/// Устаревший импорт PDF намеренно не входит в мобильный клиент: словарь
/// формируется воспроизводимым скриптом из открытого датасета.
class PdfImportRepositoryStub implements PdfImportRepository {
  @override
  Future<List<WordEntity>> importFromPdfBytes(
    List<int> bytes, {
    required String sourceId,
  }) async {
    throw UnimplementedError(
      'Используйте tools/build_dictionary.py для обновления assets/data.',
    );
  }
}
