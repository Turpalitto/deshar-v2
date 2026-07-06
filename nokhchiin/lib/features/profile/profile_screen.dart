import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/feature_flags.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_icon_image.dart';
import '../../core/design/tokens/app_spacing.dart'; // intentional-mix: spacing tokens; Figma widgets from design_system
import '../../core/design/widgets/app_scaffold.dart'; // intentional-mix: app shell scaffold
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/kids_tap_target.dart';
import '../../core/widgets/parental_gate.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _guarded(
    BuildContext context,
    WidgetRef ref, {
    required bool needsGate,
    required Future<void> Function() action,
  }) async {
    if (needsGate) {
      final ok = await ParentalGate.requestUnlock(context);
      if (!ok || !context.mounted) return;
    }
    await action();
  }

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
                child: isKids
                    ? const AppIconImage(asset: AppIcons.mascotFox, size: 36, color: Colors.white)
                    : const AppIconImage(asset: AppIcons.navProfile, size: 36, color: Colors.white),
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
                      label: isKids ? 'Детский трек' : 'Взрослый трек',
                      color: accent,
                      background: accentMuted,
                    ),
                  ],
                ),
              ),
              if (FeatureFlags.premiumEnabled && !profile.isPremium)
                KidsTapTarget(
                  minSize: isKids ? 56 : 48,
                  onTap: () => context.push('/paywall'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DesignTokens.goldMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const AppIconImage(asset: AppIcons.rewardCrown, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: NokhchiinStatTile(iconAsset: AppIcons.progressStreak, value: '${profile.streakDays}', label: 'Стрик')),
              const SizedBox(width: 10),
              Expanded(child: NokhchiinStatTile(iconAsset: AppIcons.progressStar, value: '${profile.xp}', label: 'XP')),
              const SizedBox(width: 10),
              Expanded(child: NokhchiinStatTile(iconAsset: AppIcons.navDictionary, value: '${profile.lessonsCompletedTotal}', label: 'Уроков')),
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
                      // Текст по реальному прогрессу: «Отличный прогресс!»
                      // при 0% выглядел насмешкой.
                      Text(
                        switch (weekGoalPct) {
                          0 => 'Начни сегодня — один урок!',
                          < 50 => 'Хорошее начало!',
                          < 100 => 'Почти у цели!',
                          _ => 'Цель выполнена!',
                        },
                        style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                      ),
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
                    const AppIconImage(asset: AppIcons.actionReview, size: 28),
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
              children: {
                AppMode.kids: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: isKids ? 12 : 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIconImage(asset: AppIcons.mascotFox, size: 16),
                      const SizedBox(width: 6),
                      Text('Дети', style: TextStyle(fontSize: isKids ? 15 : 13)),
                    ],
                  ),
                ),
                AppMode.adult: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: isKids ? 12 : 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIconImage(asset: AppIcons.navDictionary, size: 16),
                      const SizedBox(width: 6),
                      Text('Взрослые', style: TextStyle(fontSize: isKids ? 15 : 13)),
                    ],
                  ),
                ),
              },
              onValueChanged: (mode) {
                if (mode == null || mode == profile.mode) return;
                _guarded(
                  context,
                  ref,
                  needsGate: isKids || mode == AppMode.adult,
                  action: () async => ref.read(userProfileProvider.notifier).setMode(mode),
                );
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
              return KidsTapTarget(
                minSize: 56,
                expand: true,
                onTap: () => _guarded(
                  context,
                  ref,
                  needsGate: true,
                  action: () async => ref.read(userProfileProvider.notifier).setAgeGroup(age),
                ),
                child: RadioListTile<KidsAgeGroup>(
                  title: Text(label),
                  value: age,
                  groupValue: profile.ageGroup,
                  onChanged: null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              );
            }),
          ],
          const SizedBox(height: AppSpacing.md),
          NokhchiinSettingsRow(
            iconAsset: AppIcons.actionReview,
            label: 'Сменить режим при входе',
            onTap: () => _guarded(
              context,
              ref,
              needsGate: isKids,
              action: () async {
                if (context.mounted) context.go('/onboarding');
              },
            ),
          ),
          // Кабинет родителя был реализован и заведён в роутер, но нигде не
          // было кнопки на него — родитель, ищущий контроль за прогрессом
          // ребёнка, не находил его вообще (аудит §6). Показываем только в
          // детском треке, за родительским гейтом — тот же паттерн, что уже
          // используют смена режима и возраст выше.
          if (isKids)
            NokhchiinSettingsRow(
              iconAsset: AppIcons.navProfile,
              label: 'Кабинет родителя',
              onTap: () => _guarded(
                context,
                ref,
                needsGate: true,
                action: () async {
                  if (context.mounted) context.push('/parent');
                },
              ),
            ),
          NokhchiinSettingsRow(
            emoji: '🔔',
            label: 'Уведомления',
            trailing: Switch.adaptive(
              value: profile.notificationsEnabled,
              onChanged: (value) async {
                final ok = await ref.read(userProfileProvider.notifier).setNotificationsEnabled(value);
                if (value && !ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Включите уведомления в настройках устройства, чтобы получать напоминания'),
                  ));
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Правовая информация', style: Theme.of(context).textTheme.titleMedium),
          NokhchiinSettingsRow(
            iconAsset: AppIcons.navDictionary,
            label: 'Политика конфиденциальности',
            onTap: () => context.push('/legal/privacy'),
          ),
          NokhchiinSettingsRow(
            iconAsset: AppIcons.navProfile,
            label: 'Условия использования',
            onTap: () => context.push('/legal/terms'),
          ),
        ],
      ),
    );
  }
}
