import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/providers/providers.dart';
import 'package:nokhchiin/domain/constants/gameplay_constants.dart';
import 'package:nokhchiin/domain/entities/learning_entities.dart';
import 'package:nokhchiin/domain/repositories/repositories.dart';

class _UserRepository implements UserRepository {
  UserProfileEntity profile = const UserProfileEntity();
  int saveCount = 0;

  @override
  Future<UserProfileEntity> getProfile() async => profile;

  @override
  Future<void> saveProfile(UserProfileEntity profile) async {
    this.profile = profile;
    saveCount++;
  }
}

void main() {
  test(
    'kids session updates rewards, daily progress and duration once',
    () async {
      final repository = _UserRepository();
      final container = ProviderContainer(
        overrides: [userRepoProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(userProfileProvider.future);

      await container
          .read(userProfileProvider.notifier)
          .recordKidsSession(wordsLearned: 3, minutes: 2);

      final profile = container.read(userProfileProvider).requireValue;
      expect(profile.wordsLearnedToday, 3);
      expect(profile.todayMinutes, 2);
      expect(profile.lessonsCompletedTotal, 1);
      expect(profile.xp, 3 * GameplayConstants.wordLearnedXp);
      expect(profile.coins, 3 * GameplayConstants.wordLearnedCoins);
      expect(profile.weeklyXp.last, 3 * GameplayConstants.wordLearnedXp);
      expect(repository.profile, profile);
    },
  );
}
