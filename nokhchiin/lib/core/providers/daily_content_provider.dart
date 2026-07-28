import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/daily_content_entity.dart';
import '../../domain/services/daily_content_selector.dart';
import 'repository_providers.dart';

const _selector = DailyContentSelector();

final dailyContentForDateProvider = FutureProvider.autoDispose
    .family<DailyContentEntity?, DateTime>((ref, date) async {
      final curated = await ref.watch(dictionaryRepoProvider).getCuratedWords();
      final progress = await ref.watch(progressRepoProvider).getAllProgress();
      return _selector.select(
        date: date,
        curatedWords: curated,
        progress: progress,
      );
    });

final todayContentProvider = FutureProvider.autoDispose<DailyContentEntity?>((
  ref,
) {
  final now = DateTime.now();
  return ref.watch(
    dailyContentForDateProvider(DateTime(now.year, now.month, now.day)).future,
  );
});

final dailyHistoryProvider =
    FutureProvider.autoDispose<List<DailyContentEntity>>((ref) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final curated = await ref.watch(dictionaryRepoProvider).getCuratedWords();
      final progress = await ref.watch(progressRepoProvider).getAllProgress();
      final history = <DailyContentEntity>[];
      for (var daysAgo = 1; daysAgo <= 7; daysAgo++) {
        final selection = _selector.select(
          date: today.subtract(Duration(days: daysAgo)),
          curatedWords: curated,
          progress: progress,
        );
        if (selection != null) history.add(selection);
      }
      return history;
    });
