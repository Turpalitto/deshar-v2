/// Уровень владения словом (Mastery Learning).
enum MasteryLevel {
  unseen(0, 'Не видел'),
  seen(1, 'Увидел'),
  recognizing(2, 'Узнаёт'),
  remembering(3, 'Помнит'),
  using(4, 'Использует'),
  mastered(5, 'Освоено');

  const MasteryLevel(this.value, this.labelRu);
  final int value;
  final String labelRu;

  static MasteryLevel fromValue(int v) =>
      MasteryLevel.values.firstWhere((e) => e.value == v, orElse: () => unseen);

  MasteryLevel promote() => fromValue((value + 1).clamp(0, 5));
  MasteryLevel demote() => fromValue((value - 1).clamp(0, 5));
  bool get isLearned => value >= remembering.value;
  bool get isMastered => value >= mastered.value;
}

enum PartOfSpeech {
  noun('Существительное'),
  verb('Глагол'),
  adjective('Прилагательное'),
  adverb('Наречие'),
  phrase('Фраза'),
  number('Числительное'),
  pronoun('Местоимение'),
  other('Другое');

  const PartOfSpeech(this.labelRu);
  final String labelRu;
}

enum AppMode { kids, adult }

enum KidsAgeGroup { age3to6, age6to9, age9to12 }

enum VoiceProfile { childSlow, childNormal, adultSlow, adultNormal }
