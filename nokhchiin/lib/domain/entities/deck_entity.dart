import 'package:equatable/equatable.dart';

abstract final class SystemDeckIds {
  static const core = 'system_core';
  static const phrases = 'system_phrases';
  static const rare = 'system_rare';
  static const favorites = 'system_favorites';
  static const mistakes = 'system_mistakes';
  static const dictionary = 'system_dictionary';
  static const newWords = 'system_new';
  static const due = 'system_due';
}

class DeckEntity extends Equatable {
  const DeckEntity({
    required this.id,
    required this.title,
    required this.isSystem,
    this.createdAt,
  });

  final String id;
  final String title;
  final bool isSystem;
  final DateTime? createdAt;

  static const systemDecks = [
    DeckEntity(id: SystemDeckIds.core, title: 'Основные слова', isSystem: true),
    DeckEntity(
      id: SystemDeckIds.phrases,
      title: 'Повседневные фразы',
      isSystem: true,
    ),
    DeckEntity(id: SystemDeckIds.rare, title: 'Редкие слова', isSystem: true),
    DeckEntity(id: SystemDeckIds.favorites, title: 'Избранное', isSystem: true),
    DeckEntity(id: SystemDeckIds.mistakes, title: 'Мои ошибки', isSystem: true),
    DeckEntity(
      id: SystemDeckIds.dictionary,
      title: 'Добавлено из словаря',
      isSystem: true,
    ),
    DeckEntity(
      id: SystemDeckIds.newWords,
      title: 'Новые слова',
      isSystem: true,
    ),
    DeckEntity(id: SystemDeckIds.due, title: 'На повторение', isSystem: true),
  ];

  @override
  List<Object?> get props => [id, title, isSystem, createdAt];
}
