import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/deck_entity.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/entities/word_progress_entity.dart';
import 'repository_providers.dart';

final decksProvider = FutureProvider.autoDispose<List<DeckEntity>>(
  (ref) => ref.watch(deckRepoProvider).getDecks(),
);

final deckProvider = FutureProvider.autoDispose.family<DeckEntity?, String>(
  (ref, deckId) => ref.watch(deckRepoProvider).getDeck(deckId),
);

final deckWordsProvider = FutureProvider.autoDispose
    .family<List<WordEntity>, String>((ref, deckId) async {
      final ids = await ref.watch(deckRepoProvider).getWordIds(deckId);
      return ref.watch(dictionaryRepoProvider).getWordsByIds(ids);
    });

final wordDeckMembershipProvider = FutureProvider.autoDispose
    .family<Set<String>, String>(
      (ref, wordId) => ref.watch(deckRepoProvider).getDeckIdsForWord(wordId),
    );

final wordProgressProvider = FutureProvider.autoDispose
    .family<WordProgressEntity?, String>(
      (ref, wordId) => ref.watch(progressRepoProvider).getProgress(wordId),
    );

final allProgressProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(progressRepoProvider).getAllProgress(),
);
