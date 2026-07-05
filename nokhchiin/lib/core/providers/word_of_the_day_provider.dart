import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/entry_type.dart';
import '../../domain/repositories/dictionary_search_repository.dart';
import 'dictionary_search_providers.dart';

/// Детерминированное «слово дня» для произвольной календарной даты — один и
/// тот же результат для всех пользователей в течение дня. Вынесено отдельно
/// от [wordOfTheDayProvider], чтобы можно было заранее посчитать слово на
/// завтра (для уведомления), не дожидаясь наступления следующего дня.
Future<DictionaryEntry?> wordForDate(DictionarySearchRepository repo, DateTime date) async {
  // Первый вызов — узнать totalCount уже после фильтра по типу "слово"
  // (totalCount без фильтра включает фразы/предложения и может не совпасть
  // с реальным количеством слов).
  final probe = await repo.search(query: '', page: 0, pageSize: 1, typeFilter: EntryType.word);
  if (probe.totalCount == 0) return null;

  final seed = date.year * 372 + date.month * 31 + date.day;
  final index = seed % probe.totalCount;

  final result = await repo.search(query: '', page: index, pageSize: 1, typeFilter: EntryType.word);
  return result.entries.isEmpty ? null : result.entries.first;
}

/// «Слово дня» — одна и та же запись словаря для всех пользователей в
/// течение календарного дня. Индекс детерминирован датой, поэтому не нужно
/// хранить его отдельно — просто пересчитывается при каждом обращении.
final wordOfTheDayProvider = FutureProvider.autoDispose<DictionaryEntry?>((ref) async {
  final repo = ref.watch(dictionarySearchRepoProvider);
  return wordForDate(repo, DateTime.now());
});
