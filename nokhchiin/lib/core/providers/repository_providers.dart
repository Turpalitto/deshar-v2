import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/repository_impl.dart';
import '../../domain/repositories/repositories.dart';
import 'datasource_providers.dart';

final dictionaryRepoProvider = Provider<DictionaryRepository>(
  (ref) => DictionaryRepositoryImpl(ref.watch(assetDictSourceProvider)),
);

final progressRepoProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepositoryImpl(ref.watch(progressLocalProvider)),
);

final learningPathRepoProvider = Provider<LearningPathRepository>(
  (ref) => LearningPathRepositoryImpl(
    ref.watch(assetDictSourceProvider),
    ref.watch(dictionaryRepoProvider),
  ),
);

final userRepoProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(ref.watch(userLocalProvider)),
);
