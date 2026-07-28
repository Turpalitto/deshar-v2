import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/daily_content_entity.dart';
import '../../domain/entities/daily_session_entity.dart';
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
    FutureProvider.autoDispose<List<DailySessionEntity>>(
      (ref) => ref.watch(dailySessionRepoProvider).getRecent(),
    );
