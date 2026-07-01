import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/enums.dart';
import '../../core/theme/app_colors.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Нохчийн',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ).animate().fadeIn().slideY(begin: 0.2),
              const SizedBox(height: 8),
              Text(
                'Лучший путь к чеченскому языку',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 48),
              _ModeCard(
                title: 'Детский режим',
                subtitle: 'Игра, истории, большие кнопки',
                emoji: '🦊',
                color: AppColors.kidsSky,
                onTap: () async {
                  await ref.read(userProfileProvider.notifier).setMode(AppMode.kids);
                  if (context.mounted) _showAgePicker(context, ref);
                },
              ).animate().fadeIn(delay: 200.ms).slideX(),
              const SizedBox(height: 16),
              _ModeCard(
                title: 'Взрослый режим',
                subtitle: 'Карточки, грамматика, статистика',
                emoji: '📚',
                color: AppColors.primaryLight,
                onTap: () async {
                  await ref.read(userProfileProvider.notifier).setMode(AppMode.adult);
                  if (context.mounted) context.go('/');
                },
              ).animate().fadeIn(delay: 300.ms).slideX(),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _showAgePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Сколько лет?', style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 20),
            _AgeButton(label: '3–6 лет', age: KidsAgeGroup.age3to6),
            _AgeButton(label: '6–9 лет', age: KidsAgeGroup.age6to9),
            _AgeButton(label: '9–12 лет', age: KidsAgeGroup.age9to12),
          ],
        ),
      ),
    );
  }
}

class _AgeButton extends ConsumerWidget {
  const _AgeButton({required this.label, required this.age});
  final String label;
  final KidsAgeGroup age;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: () async {
          await ref.read(userProfileProvider.notifier).setAgeGroup(age);
          if (context.mounted) {
            Navigator.pop(context);
            context.go('/');
          }
        },
        child: Text(label),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  final String title, subtitle, emoji;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
