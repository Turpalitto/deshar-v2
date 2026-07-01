import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value ?? const UserProfileEntity();
    final isKids = profile.mode == AppMode.kids;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Text(isKids ? '🦊' : '📚', style: const TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Уровень ${profile.level}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Center(
            child: Text('${profile.xp} XP · ${profile.stars} ⭐ · ${profile.streakDays} дн. серия'),
          ),
          const SizedBox(height: 28),
          Text('Режим обучения', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<AppMode>(
              groupValue: profile.mode,
              children: const {
                AppMode.kids: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('🦊 Дети'),
                ),
                AppMode.adult: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('📚 Взрослые'),
                ),
              },
              onValueChanged: (mode) {
                if (mode != null) {
                  ref.read(userProfileProvider.notifier).setMode(mode);
                }
              },
            ),
          ),
          if (isKids) ...[
            const SizedBox(height: 20),
            Text('Возраст', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...KidsAgeGroup.values.map((age) {
              final label = switch (age) {
                KidsAgeGroup.age3to6 => '3–6 лет',
                KidsAgeGroup.age6to9 => '6–9 лет',
                KidsAgeGroup.age9to12 => '9–12 лет',
              };
              return RadioListTile<KidsAgeGroup>(
                title: Text(label),
                value: age,
                groupValue: profile.ageGroup,
                onChanged: (v) {
                  if (v != null) ref.read(userProfileProvider.notifier).setAgeGroup(v);
                },
              );
            }),
          ],
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Словарь'),
            subtitle: const Text('Мациев 7784 + Алироев 53 + проверенная лексика'),
          ),
          ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: const Text('Исправления'),
            subtitle: const Text('Лерг = ухо (не «лор»); аудит vocabulary_corrections.json'),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded),
            title: const Text('Сменить режим при входе'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/onboarding'),
          ),
        ],
      ),
    );
  }
}
