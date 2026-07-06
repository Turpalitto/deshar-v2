import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/providers/datasource_providers.dart';
import 'package:nokhchiin/core/providers/dictionary_search_providers.dart';
import 'package:nokhchiin/core/providers/repository_providers.dart';
import 'package:nokhchiin/data/datasources/asset_dictionary_datasource.dart';
import 'package:nokhchiin/domain/core/result.dart';
import 'package:nokhchiin/domain/entities/word_entity.dart';
import 'package:nokhchiin/domain/entities/word_progress_entity.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';

// --- Fakes ---

class _FakeDictionaryDataSource extends AssetDictionaryDataSource {
  _FakeDictionaryDataSource(this._words);

  final List<WordEntity> _words;
  bool shouldFail = false;

  @override
  Future<Result<List<WordEntity>>> loadBundledDictionary() async {
    if (shouldFail) return Failure(Exception('boom'));
    return Success(_words);
  }
}

class _FakeProgressRepo implements ProgressRepository {
  final Map<String, WordProgressEntity> _data = {};

  @override
  Future<WordProgressEntity?> getProgress(String wordId) async => _data[wordId];

  @override
  Future<Map<String, WordProgressEntity>> getAllProgress() async => _data;

  @override
  Future<void> saveProgress(WordProgressEntity progress) async {
    _data[progress.wordId] = progress;
  }

  @override
  Future<List<WordProgressEntity>> getDueForReview() async => const [];

  @override
  Future<List<String>> getFavorites() async =>
      _data.values.where((p) => p.isFavorite).map((p) => p.wordId).toList();

  @override
  Future<void> toggleFavorite(String wordId) async {
    final p = _data[wordId] ?? WordProgressEntity(wordId: wordId);
    _data[wordId] = p.copyWith(isFavorite: !p.isFavorite);
  }
}

// --- Test data ---

List<WordEntity> _generateWords(int count) {
  return List.generate(count, (i) {
    final n = i.toString().padLeft(3, '0');
    return WordEntity(id: 'w$n', chechen: 'слово$n', russian: 'слово $n');
  });
}

/// Строит container с фейковыми data source/progress repo и держит
/// dictionarySearchProvider живым на время теста (иначе autoDispose
/// снесёт состояние между обращениями к container.read).
ProviderContainer _makeContainer(_FakeDictionaryDataSource dataSource, {ProgressRepository? progress}) {
  final container = ProviderContainer(overrides: [
    assetDictSourceProvider.overrideWithValue(dataSource),
    progressRepoProvider.overrideWithValue(progress ?? _FakeProgressRepo()),
  ]);
  addTearDown(container.dispose);
  container.listen(dictionarySearchProvider, (_, __) {});
  return container;
}

void main() {
  group('DictionarySearchNotifier — пагинация', () {
    test('loadMore дописывает страницы, а не заменяет их', () async {
      final container = _makeContainer(_FakeDictionaryDataSource(_generateWords(100)));

      final first = await container.read(dictionarySearchProvider.future);
      expect(first.entries.length, 40);
      expect(first.hasMore, isTrue);

      await container.read(dictionarySearchProvider.notifier).loadMore();
      final second = container.read(dictionarySearchProvider).value!;
      expect(second.entries.length, 80);
      expect(
        second.entries.take(40).map((e) => e.id).toList(),
        first.entries.map((e) => e.id).toList(),
      );

      await container.read(dictionarySearchProvider.notifier).loadMore();
      final third = container.read(dictionarySearchProvider).value!;
      expect(third.entries.length, 100);
      expect(third.hasMore, isFalse);

      // Страницы кончились — повторный loadMore ничего не меняет.
      await container.read(dictionarySearchProvider.notifier).loadMore();
      expect(container.read(dictionarySearchProvider).value!.entries.length, 100);
    });

    test('смена запроса сбрасывает список на страницу 0', () async {
      final container = _makeContainer(_FakeDictionaryDataSource(_generateWords(100)));

      await container.read(dictionarySearchProvider.future);
      await container.read(dictionarySearchProvider.notifier).loadMore();
      expect(container.read(dictionarySearchProvider).value!.entries.length, 80);

      container.read(dictionaryQueryProvider.notifier).state = 'слово001';
      final afterQuery = await container.read(dictionarySearchProvider.future);

      expect(afterQuery.page, 0);
      expect(afterQuery.entries, isNotEmpty);
      expect(
        afterQuery.entries.every((e) => e.chechen.contains('слово001')),
        isTrue,
      );
    });

    test('смена фильтра сбрасывает список на страницу 0', () async {
      final container = _makeContainer(_FakeDictionaryDataSource(_generateWords(100)));

      await container.read(dictionarySearchProvider.future);
      await container.read(dictionarySearchProvider.notifier).loadMore();
      expect(container.read(dictionarySearchProvider).value!.page, 1);

      container.read(dictionaryFilterProvider.notifier).state = DictionaryFilter.favorites;
      final afterFilter = await container.read(dictionarySearchProvider.future);

      expect(afterFilter.page, 0);
      expect(afterFilter.entries, isEmpty); // ни одно слово ещё не в избранном
    });
  });

  group('DictionarySearchNotifier — ошибки загрузки', () {
    test('провал загрузки становится реальной ошибкой, а не пустым результатом', () async {
      final dataSource = _FakeDictionaryDataSource(_generateWords(10))..shouldFail = true;
      final container = _makeContainer(dataSource);

      await expectLater(
        container.read(dictionarySearchProvider.future),
        throwsA(isA<Exception>()),
      );
      expect(container.read(dictionarySearchProvider).hasError, isTrue);
    });

    test('после провала повтор (invalidate) реально перезагружает данные', () async {
      final dataSource = _FakeDictionaryDataSource(_generateWords(10))..shouldFail = true;
      final container = _makeContainer(dataSource);

      await expectLater(container.read(dictionarySearchProvider.future), throwsA(anything));

      dataSource.shouldFail = false;
      container.invalidate(dictionarySearchProvider);

      final result = await container.read(dictionarySearchProvider.future);
      expect(result.entries.length, 10);
    });
  });

  group('Единый id между словарём и остальным приложением', () {
    test('DictionaryEntry.id совпадает с исходным WordEntity.id', () async {
      final words = [
        const WordEntity(id: 'known-id-123', chechen: 'бер', russian: 'Ребёнок'),
        ..._generateWords(5),
      ];
      final container = _makeContainer(_FakeDictionaryDataSource(words));

      await container.read(dictionarySearchProvider.future);

      final entry = await container.read(dictionarySearchRepoProvider).getById('known-id-123');
      expect(entry, isNotNull);
      expect(entry!.chechen, 'бер');
      expect(entry.russian, 'Ребёнок');

      // Избранное, поставленное по этому id, должно быть видно при повторном чтении —
      // т.е. это тот же id, под которым прогресс хранится в остальном приложении.
      await container.read(dictionarySearchProvider.notifier).toggleFavorite('known-id-123');
      final refetched = await container.read(dictionarySearchRepoProvider).getById('known-id-123');
      expect(refetched!.favorite, isTrue);
    });
  });
}
