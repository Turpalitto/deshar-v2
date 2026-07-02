import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';
import '../../core/design_system/design_system.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value ?? const UserProfileEntity();
    final isKids = profile.mode == AppMode.kids;
    final accent = isKids ? DesignTokens.meadow : context.iosTokens.accent;
    final accentMuted = isKids ? DesignTokens.meadowMuted : context.iosTokens.accentMuted;
    final weekDone = profile.weeklyXp.where((x) => x > 0).length;
    final weekGoalPct = (weekDone / 7 * 100).round();

    return AppScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(22)),
                alignment: Alignment.center,
                child: Text(isKids ? '🦊' : '👤', style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Уровень ${profile.level}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    NokhchiinChip(
                      label: isKids ? 'Детский трек 🦊' : 'Взрослый трек',
                      color: accent,
                      background: accentMuted,
                    ),
                  ],
                ),
              ),
              if (!profile.isPremium)
                IconButton(
                  onPressed: () => context.push('/paywall'),
                  style: IconButton.styleFrom(backgroundColor: DesignTokens.goldMuted),
                  icon: const Text('👑', style: TextStyle(fontSize: 18)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: NokhchiinStatTile(emoji: '🔥', value: '${profile.streakDays}', label: 'Стрик')),
              const SizedBox(width: 10),
              Expanded(child: NokhchiinStatTile(emoji: '⭐', value: '${profile.xp}', label: 'XP')),
              const SizedBox(width: 10),
              Expanded(child: NokhchiinStatTile(emoji: '📚', value: '${profile.lessonsCompletedTotal}', label: 'Уроков')),
            ],
          ),
          const SizedBox(height: 14),
          NokhchiinSurfaceCard(
            radius: 22,
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                NokhchiinArcProgress(
                  progress: weekGoalPct / 100,
                  size: 90,
                  strokeWidth: 7,
                  center: Text(
                    '$weekGoalPct%',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Недельная цель', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text('$weekDone из 7 дней с XP', style: Theme.of(context).textTheme.bodySmall),
                      Text('Отличный прогресс!', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          NokhchiinSurfaceCard(
            onTap: () => context.push(isKids ? '/progress' : '/insights'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'СЛАБОЕ МЕСТО',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: context.iosTokens.textTertiary,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('🔢', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isKids ? 'Повтори слова' : 'Инсайты и практика',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: accent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Интервальное повторение (SRS) — открой раздел «Повтор» в таб-баре.',
              style: Theme.of(context).textTheme.bodySmall,
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
          const SizedBox(height: AppSpacing.md),
          NokhchiinSettingsRow(
            emoji: '🔄',
            label: 'Сменить режим при входе',
            onTap: () => context.go('/onboarding'),
          ),
        ],
      ),
    );
  }
}
