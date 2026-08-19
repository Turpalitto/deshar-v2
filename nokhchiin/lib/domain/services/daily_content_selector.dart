import '../entities/daily_content_entity.dart';
import '../entities/content_metadata.dart';
import '../entities/enums.dart';
import '../entities/word_entity.dart';
import '../entities/word_progress_entity.dart';

class DailyContentSelector {
  const DailyContentSelector();

  WordEntity? wordOfDayForDate({
    required DateTime date,
    required List<WordEntity> curatedWords,
  }) {
    final words =
        curatedWords
            .where((word) => word.reviewStatus.canAppearInDailyContent)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id))
          ..removeWhere((word) => word.isPhrase);
    if (words.isEmpty) return null;
    return _pickOne(words, date, salt: 3);
  }

  DailyContentEntity? select({
    required DateTime date,
    required List<WordEntity> curatedWords,
    required Map<String, WordProgressEntity> progress,
  }) {
    final sorted =
        curatedWords
            .where((word) => word.reviewStatus.canAppearInDailyContent)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    if (sorted.isEmpty) return null;
    final words = sorted.where((word) => !word.isPhrase).toList();
    if (words.isEmpty) return null;

    final unseen = words
        .where(
          (word) =>
              (progress[word.id]?.mastery ?? MasteryLevel.unseen) ==
              MasteryLevel.unseen,
        )
        .toList();
    final targetCount = words.length < 5 ? words.length : 5;
    final newWords = [..._pickMany(unseen, date, salt: 17, count: targetCount)];
    if (newWords.length < targetCount) {
      for (final word in _pickMany(
        words,
        date,
        salt: 19,
        count: words.length,
      )) {
        if (newWords.any((candidate) => candidate.id == word.id)) continue;
        newWords.add(word);
        if (newWords.length == targetCount) break;
      }
    }
    final allSelectedWordsAreUnseen =
        newWords.isNotEmpty &&
        newWords.every(
          (word) =>
              (progress[word.id]?.mastery ?? MasteryLevel.unseen) ==
              MasteryLevel.unseen,
        );
    final wordOfTheDay = wordOfDayForDate(date: date, curatedWords: sorted)!;

    final phrases = sorted.where((word) => word.isPhrase).toList();
    final phrase = phrases.isEmpty ? null : _pickOne(phrases, date, salt: 29);

    final rare = words
        .where((word) => word.frequencyTier == FrequencyTier.rare)
        .toList();
    final uncommon = words
        .where((word) => word.frequencyTier == FrequencyTier.uncommon)
        .toList();
    final rareWord = _pickOne(
      rare.isNotEmpty ? rare : (uncommon.isNotEmpty ? uncommon : words),
      date,
      salt: 43,
    );

    final quizWords = <WordEntity>[...newWords];
    for (final word in _pickMany(words, date, salt: 61, count: 5)) {
      if (quizWords.any((candidate) => candidate.id == word.id)) continue;
      quizWords.add(word);
      if (quizWords.length == 5) break;
    }

    return DailyContentEntity(
      date: DateTime(date.year, date.month, date.day),
      wordOfTheDay: wordOfTheDay,
      newWords: newWords,
      phraseOfTheDay: phrase,
      rareWordOfTheDay: rareWord,
      quizWords: quizWords.take(5).toList(),
      newWordsAreUnseen: allSelectedWordsAreUnseen,
    );
  }

  WordEntity _pickOne(
    List<WordEntity> pool,
    DateTime date, {
    required int salt,
  }) {
    return pool[_seed(date, salt) % pool.length];
  }

  List<WordEntity> _pickMany(
    List<WordEntity> pool,
    DateTime date, {
    required int salt,
    required int count,
  }) {
    if (pool.isEmpty) return const [];
    final start = _seed(date, salt) % pool.length;
    final result = <WordEntity>[];
    for (
      var offset = 0;
      offset < pool.length && result.length < count;
      offset++
    ) {
      result.add(pool[(start + offset) % pool.length]);
    }
    return result;
  }

  int _seed(DateTime date, int salt) =>
      date.year * 372 + date.month * 31 + date.day + salt * 997;
}
