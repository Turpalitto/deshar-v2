import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nokhchiin/data/datasources/local_storage_datasource.dart';
import 'package:nokhchiin/data/repositories/daily_session_repository_impl.dart';
import 'package:nokhchiin/domain/entities/daily_session_entity.dart';

void main() {
  late Directory hiveDirectory;
  late LocalDailySessionDataSource dataSource;
  late DailySessionRepositoryImpl repository;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('daily-session-test');
    Hive.init(hiveDirectory.path);
    dataSource = LocalDailySessionDataSource();
    await dataSource.init();
    repository = DailySessionRepositoryImpl(dataSource);
  });

  tearDown(() async {
    await Hive.box<Map>(LocalDailySessionDataSource.boxName).close();
    await hiveDirectory.delete(recursive: true);
  });

  test('persists and returns actual sessions in newest-first order', () async {
    const olderWords = ['w1', 'w2'];
    final older = DailySessionEntity(
      date: DateTime(2026, 7, 27),
      selectedWordIds: olderWords,
      completedTaskIds: const ['new_words'],
      minutesSpent: 4,
      finishedAt: DateTime(2026, 7, 27, 10),
    );
    final newer = DailySessionEntity(
      date: DateTime(2026, 7, 28),
      selectedWordIds: const ['w3'],
      completedTaskIds: const ['quiz'],
      quizScore: 4,
      quizTotal: 5,
      minutesSpent: 2,
      finishedAt: DateTime(2026, 7, 28, 11),
    );

    await repository.save(older);
    await repository.save(newer);

    expect(await repository.getForDate(older.date), older);
    final recent = await repository.getRecent();
    expect(recent, [newer, older]);
  });
}
