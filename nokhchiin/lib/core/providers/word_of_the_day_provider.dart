import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/repositories.dart';
import 'repository_providers.dart';

/// Детерминированное «слово дня» для произвольной календарной даты — один и
/// тот же результат для всех пользователей в течение дня. Вынесено отдельно
/// от [wordOfTheDayProvider], чтобы можно было заранее посчитать слово на
/// завтра (для уведомления), не дожидаясь наступления следующего дня.
///
/// Берёт слово из curated-набора (~330 проверенных записей), а не из полного
/// словаря: во-первых, полный словарь — это 134k сырых записей из датасета,
/// и «словом дня» оказывались случайные технические термины вроде
/// «Подошвенные плюсневые артерии»; во-вторых, его парсинг (23 МБ JSON) на
/// web выполняется в главном потоке (compute() без изолята) и замораживал UI
/// на первом кадре Home.
Future<WordEntity?> wordForDate(DictionaryRepository repo, DateTime date) async {
  final all = await repo.getCuratedWords();
  if (all.isEmpty) return null;

  final seed = date.year * 372 + date.month * 31 + date.day;
  final index = seed % all.length;
  return all[index];
}

/// «Слово дня» — одна и та же запись словаря для всех пользователей в
/// течение календарного дня. Индекс детерминирован датой, поэтому не нужно
/// хранить его отдельно — просто пересчитывается при каждом обращении.
final wordOfTheDayProvider = FutureProvider.autoDispose<WordEntity?>((ref) async {
  final repo = ref.watch(dictionaryRepoProvider);
  return wordForDate(repo, DateTime.now());
});
