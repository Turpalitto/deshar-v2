import 'package:equatable/equatable.dart';

import 'word_entity.dart';

enum VocabularyQuizType {
  chooseMeaning,
  chooseWord,
  chooseImage,
  chooseReply,
  answerReply,
  completePhrase,
  assemblePhrase,
  findWordInContext,
  repeatMistakes;

  static VocabularyQuizType? fromJson(Object? value) {
    if (value is! String) return null;
    for (final type in values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

class ConversationEntryRef extends Equatable {
  const ConversationEntryRef({
    required this.chechen,
    required this.russian,
    this.quizTypes = const [],
  });

  final String chechen;
  final String russian;
  final List<VocabularyQuizType> quizTypes;

  @override
  List<Object?> get props => [chechen, russian, quizTypes];
}

class ConversationCategoryDefinition extends Equatable {
  const ConversationCategoryDefinition({
    required this.id,
    required this.title,
    required this.icon,
    required this.enabled,
    this.entries = const [],
  });

  final String id;
  final String title;
  final String icon;
  final bool enabled;
  final List<ConversationEntryRef> entries;

  @override
  List<Object?> get props => [id];
}

class ConversationCategoryEntity extends Equatable {
  const ConversationCategoryEntity({
    required this.id,
    required this.title,
    required this.icon,
    required this.enabled,
    this.entries = const [],
    this.quizTypesByWordId = const {},
  });

  final String id;
  final String title;
  final String icon;
  final bool enabled;
  final List<WordEntity> entries;
  final Map<String, List<VocabularyQuizType>> quizTypesByWordId;

  Set<VocabularyQuizType> get supportedQuizTypes => {
    for (final types in quizTypesByWordId.values) ...types,
  };

  @override
  List<Object?> get props => [id, entries, quizTypesByWordId];
}
