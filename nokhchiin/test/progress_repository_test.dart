import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nokhchiin/data/datasources/local_storage_datasource.dart';
import 'package:nokhchiin/data/repositories/progress_repository_impl.dart';
import 'package:nokhchiin/domain/entities/enums.dart';
import 'package:nokhchiin/domain/entities/word_progress_entity.dart';

void main() {
  late Directory hiveDirectory;
  late LocalProgressDataSource dataSource;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'nokhchiin_progress_test_',
    );
    Hive.init(hiveDirectory.path);
    dataSource = LocalProgressDataSource();
    await dataSource.init();
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('saves and restores complete SRS progress after box reopen', () async {
    final reviewedAt = DateTime(2026, 7, 28, 9);
    final progress = WordProgressEntity(
      wordId: 'word-1',
      mastery: MasteryLevel.remembering,
      easeFactor: 2.2,
      intervalDays: 3,
      repetitions: 2,
      nextReviewAt: DateTime(2026, 7, 31, 9),
      lastReviewedAt: reviewedAt,
      lastSuccessfulReviewAt: reviewedAt,
      successfulReviewDays: 2,
      correctStreak: 2,
      wrongCount: 1,
      isFavorite: true,
    );

    await dataSource.save(progress);
    await Hive.box<Map>(LocalProgressDataSource.boxName).close();
    await dataSource.init();

    expect(await dataSource.get('word-1'), progress);
  });

  test('migrates legacy map without dropping existing progress', () async {
    final reviewedAt = DateTime(2026, 7, 20, 12);
    final nextReviewAt = DateTime(2026, 8, 20, 12);
    await Hive.box<Map>(LocalProgressDataSource.boxName).put('legacy-word', {
      'mastery': MasteryLevel.mastered.value,
      'easeFactor': 2.1,
      'intervalDays': 31,
      'repetitions': 8,
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'lastReviewedAt': reviewedAt.toIso8601String(),
      'correctStreak': 6,
      'wrongCount': 2,
      'isFavorite': true,
      'seededFromPlacement': false,
    });

    final migrated = await dataSource.get('legacy-word');

    expect(migrated, isNotNull);
    expect(migrated!.mastery, MasteryLevel.mastered);
    expect(migrated.repetitions, 8);
    expect(migrated.intervalDays, 31);
    expect(migrated.nextReviewAt, nextReviewAt);
    expect(migrated.lastSuccessfulReviewAt, reviewedAt);
    expect(migrated.successfulReviewDays, 3);
    expect(migrated.isFavorite, isTrue);
  });

  test('due queue uses next review time and includes failed cards', () async {
    final now = DateTime(2026, 7, 28, 12);
    await dataSource.save(
      WordProgressEntity(
        wordId: 'failed-due',
        mastery: MasteryLevel.seen,
        repetitions: 0,
        wrongCount: 1,
        nextReviewAt: now.subtract(const Duration(minutes: 1)),
      ),
    );
    await dataSource.save(
      WordProgressEntity(
        wordId: 'future',
        mastery: MasteryLevel.recognizing,
        repetitions: 4,
        nextReviewAt: now.add(const Duration(hours: 1)),
      ),
    );
    await dataSource.save(
      const WordProgressEntity(
        wordId: 'placement-only',
        mastery: MasteryLevel.mastered,
        seededFromPlacement: true,
      ),
    );

    final repository = ProgressRepositoryImpl(dataSource);
    final due = await repository.getDueForReview(now: now);

    expect(due.map((item) => item.wordId), ['failed-due']);
  });
}
