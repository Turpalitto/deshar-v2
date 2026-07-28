import 'word_entity.dart';

class DailyContentEntity {
  const DailyContentEntity({
    required this.date,
    required this.wordOfTheDay,
    required this.newWords,
    required this.phraseOfTheDay,
    required this.rareWordOfTheDay,
    required this.quizWords,
  });

  final DateTime date;
  final WordEntity wordOfTheDay;
  final List<WordEntity> newWords;
  final WordEntity? phraseOfTheDay;
  final WordEntity? rareWordOfTheDay;
  final List<WordEntity> quizWords;
}
