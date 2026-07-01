import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/learning_entities.dart';
import '../../core/widgets/mastery_progress_bar.dart';
import '../../core/widgets/stat_pill.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value ?? const UserProfileEntity();
    final isKids = profile.mode == AppMode.kids;
    final units = ref.watch(learningUnitsProvider);
    final due = ref.watch(dueWordsProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isKids ? 'Салам! 👋' : 'Нохчийн Академия',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: isKids ? 28 : 24),
                          ),
                          Text(
                            isKids ? 'Поехали учиться!' : 'Продолжайте свой путь',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    StatPill(icon: '🔥', value: '${profile.streakDays}'),
                    const SizedBox(width: 8),
                    StatPill(icon: '⭐', value: '${profile.stars}'),
                    IconButton(
                      onPressed: () => context.push('/profile'),
                      icon: const Icon(Icons.person_outline_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: _ContinueCard(
                  isKids: isKids,
                  onTap: () => context.push('/path'),
                ).animate().fadeIn().slideY(begin: 0.1),
              ),
            ),
            if (due.valueOrNull?.isNotEmpty == true)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _ReviewBanner(
                    count: due.value!.length,
                    onTap: () => context.push('/review'),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text('Путь обучения', style: Theme.of(context).textTheme.headlineMedium),
              ),
            ),
            units.when(
              data: (list) => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final u = list[i];
                      return _UnitTile(
                        unit: u,
                        isKids: isKids,
                        onTap: u.isUnlocked
                            ? () => context.push('/unit/${u.id}')
                            : null,
                      ).animate(delay: (i * 60).ms).fadeIn().slideX();
                    },
                    childCount: list.length,
                  ),
                ),
              ),
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickAction(
                      icon: Icons.menu_book_rounded,
                      label: 'Словарь',
                      onTap: () => context.push('/dictionary'),
                    ),
                    _QuickAction(
                      icon: Icons.map_rounded,
                      label: 'Миры',
                      onTap: () => context.push('/worlds'),
                    ),
                    _QuickAction(
                      icon: Icons.auto_stories_rounded,
                      label: 'Истории',
                      onTap: () => context.push('/stories'),
                    ),
                    _QuickAction(
                      icon: Icons.collections_bookmark_rounded,
                      label: 'Коллекции',
                      onTap: () => context.push('/collections'),
                    ),
                    _QuickAction(
                      icon: Icons.smart_toy_rounded,
                      label: 'AI-учитель',
                      onTap: () => context.push('/tutor'),
                    ),
                    if (!isKids)
                      _QuickAction(
                        icon: Icons.family_restroom_rounded,
                        label: 'Родителям',
                        onTap: () => context.push('/parent'),
                      ),
                  ],
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.isKids, required this.onTap});
  final bool isKids;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(isKids ? 28 : 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isKids ? 28 : 20),
        child: Padding(
          padding: EdgeInsets.all(isKids ? 28 : 22),
          child: Row(
            children: [
              Text(isKids ? '🦊' : '▶', style: TextStyle(fontSize: isKids ? 48 : 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Продолжить',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Открыть путь обучения',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: const Text('🔄', style: TextStyle(fontSize: 28)),
          title: Text('$count слов ждут повторения'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({required this.unit, required this.isKids, this.onTap});
  final dynamic unit;
  final bool isKids;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = !unit.isUnlocked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: locked ? 0.5 : 1,
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(isKids ? 24 : 16),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(locked ? '🔒' : _iconEmoji(unit.icon), style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(unit.titleCe, style: Theme.of(context).textTheme.labelLarge),
                        Text(unit.titleRu, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        MasteryProgressBar(percent: unit.masteryPercent),
                      ],
                    ),
                  ),
                  if (!locked) const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _iconEmoji(String icon) => switch (icon) {
        'paw' => '🐾',
        'home' => '🏠',
        'heart' => '❤️',
        'food' => '🍎',
        'book' => '📚',
        'tree' => '🌳',
        'bolt' => '⚡',
        'palette' => '🎨',
        'chat' => '💬',
        'people' => '👥',
        'story' => '📖',
        _ => '📘',
      };
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label),
      onPressed: onTap,
    );
  }
}