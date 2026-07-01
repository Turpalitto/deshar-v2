import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value ?? const UserProfileEntity();
    final isKids = profile.mode == AppMode.kids;

    return AppScaffold(
      title: 'Профиль',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              children: [
                Text(isKids ? '🦊' : '📚', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: AppSpacing.sm),
                Text('Уровень ${profile.level}', style: Theme.of(context).textTheme.headlineMedium),
                Text('${profile.xp} XP · 🪙 ${profile.coins} · 🔥 ${profile.streakDays} дн.'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Режим обучения', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
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
                if (mode != null) ref.read(userProfileProvider.notifier).setMode(mode);
              },
            ),
          ),
          if (isKids) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Возраст', style: Theme.of(context).textTheme.titleLarge),
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
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            onTap: () => context.push('/progress'),
            child: const ListTile(
              leading: Icon(Icons.insights_rounded),
              title: Text('Статистика'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ),
          AppCard(
            onTap: () => context.go('/onboarding'),
            child: const ListTile(
              leading: Icon(Icons.swap_horiz_rounded),
              title: Text('Сменить режим при входе'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
