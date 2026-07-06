import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/repositories.dart';
import 'repository_providers.dart';

/// Детерминированное «слово дня» для произвольной календарной даты — один и
/// тот же результат для всех пользователей в течение дня. Вынесено отдельно
/// от [wordOfTheDayProvider], чтобы можно было заранее посчитать слово на
/// завтра (для уведомления), не дожидаясь наступления следующего дня.
///
/// Намеренно берёт слово из [DictionaryRepository] (WordEntity, парсится в
/// compute()-изоляте), а не из [DictionarySearchRepository] — последний
/// строит полный инвертированный индекс (~134k слов, префиксы для каждого
/// слова ≥3 символов) на UI-исолейте без единого compute()/Isolate.run().
/// Раньше эта карточка на Home безусловно триггерила ту сборку на первом же
/// кадре — риск фриза/OOM (аудит §4). id совпадают между двумя
/// представлениями по построению (см. dictionary_search_repository_impl.dart:
/// idFactory переиспользует WordEntity.id), поэтому переход на
/// DictionaryRepository не ломает навигацию в карточке словаря по клику.
Future<WordEntity?> wordForDate(DictionaryRepository repo, DateTime date) async {
  final all = await repo.getAllWords();
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
