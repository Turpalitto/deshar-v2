import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_icons.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';
import '../today/today_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(userProfileProvider).value ?? const UserProfileEntity();
    if (profile.mode == AppMode.adult) return const TodayScreen();
    return _KidsHome(profile: profile);
  }
}

class _KidsHome extends ConsumerWidget {
  const _KidsHome({required this.profile});

  final UserProfileEntity profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(todayContentProvider);
    final phrase = daily.valueOrNull?.phraseOfTheDay;
    return AppScaffold(
      showOrnament: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const AppIconImage(asset: AppIcons.mascotFox, size: 54),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Привет!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          '${profile.wordsLearnedToday} из ${profile.dailyGoalWords} слов сегодня',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (phrase != null) ...[
                Text(
                  phrase.chechen,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  phrase.russian,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              FilledButton.icon(
                key: const Key('kids_continue'),
                onPressed: () => context.push('/kids/session'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Продолжить'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: () => context.push('/worlds'),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Миры'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
