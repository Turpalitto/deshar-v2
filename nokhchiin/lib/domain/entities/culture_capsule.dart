import 'package:equatable/equatable.dart';

/// Культурная интерлюдия между юнитами пути обучения.
class CultureCapsule extends Equatable {
  const CultureCapsule({
    required this.id,
    required this.title,
    required this.body,
    required this.relatedUnitId,
    required this.eyebrow,
    required this.tags,
    this.imagePath,
    this.featuredWord,
  });

  final String id;
  final String title;

  /// Один или два абзаца. Разделитель — пустая строка (`\n\n`).
  final String body;

  /// Опционально: `Image.asset(imagePath!)`.
  final String? imagePath;

  /// Юнит, к которому привязана капсула (`LearningUnitEntity.id`).
  final String relatedUnitId;

  /// Тематическая рубрика над заголовком, например
  /// «ЦВЕТА · НАБЛЮДЕНИЕ». Не должна быть общей для всех капсул.
  final String eyebrow;

  /// Три коротких тематических маркера, связанные с содержанием капсулы.
  final List<String> tags;

  /// Слово только из урока [relatedUnitId]. Для капсул отключённых юнитов
  /// без урока может отсутствовать.
  final CultureCapsuleWord? featuredWord;

  List<String> get paragraphs => body
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  @override
  List<Object?> get props => [id];
}

class CultureCapsuleWord extends Equatable {
  const CultureCapsuleWord({
    required this.chechen,
    required this.russian,
    required this.pronunciation,
  });

  final String chechen;
  final String russian;
  final String pronunciation;

  @override
  List<Object?> get props => [chechen, russian, pronunciation];
}
