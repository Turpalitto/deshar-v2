import 'package:equatable/equatable.dart';

/// Культурная интерлюдия между юнитами пути обучения.
class CultureCapsule extends Equatable {
  const CultureCapsule({
    required this.id,
    required this.title,
    required this.body,
    required this.relatedUnitId,
    this.imagePath,
  });

  final String id;
  final String title;

  /// Один или два абзаца. Разделитель — пустая строка (`\n\n`).
  final String body;

  /// Опционально: `Image.asset(imagePath!)`.
  final String? imagePath;

  /// Юнит, к которому привязана капсула (`LearningUnitEntity.id`).
  final String relatedUnitId;

  List<String> get paragraphs =>
      body.split(RegExp(r'\n\s*\n')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

  @override
  List<Object?> get props => [id];
}
