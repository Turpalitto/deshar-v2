import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/design_system.dart';
import '../app_icons.dart';
import '../../providers/providers.dart';
import '../../../domain/entities/enums.dart';

class AppNavigationConfig {
  const AppNavigationConfig({
    required this.labels,
    required this.routes,
    required this.iconAssets,
  });

  final List<String> labels;
  final List<String> routes;
  final List<String> iconAssets;

  factory AppNavigationConfig.forMode(AppMode mode) {
    if (mode == AppMode.kids) {
      return const AppNavigationConfig(
        labels: ['Главная', 'Игры', 'Фразы', 'Профиль'],
        routes: ['/', '/games', '/phrases', '/profile'],
        iconAssets: [
          AppIcons.navHome,
          AppIcons.gamePlay,
          AppIcons.cultureHeritage,
          AppIcons.navProfile,
        ],
      );
    }
    return const AppNavigationConfig(
      labels: ['Сегодня', 'Карточки', 'Словарь', 'Профиль'],
      routes: ['/', '/collections', '/dictionary', '/profile'],
      iconAssets: [
        AppIcons.navHome,
        AppIcons.actionCollections,
        AppIcons.navDictionary,
        AppIcons.navProfile,
      ],
    );
  }
}

/// Нижняя навигация в стиле Figma Make.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, int index, AppNavigationConfig config) {
    context.go(config.routes[index]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final mode = profile?.mode ?? AppMode.kids;
    final isKids = mode == AppMode.kids;
    final config = AppNavigationConfig.forMode(mode);
    final accent = isKids ? DesignTokens.meadow : context.iosTokens.accent;

    return Scaffold(
      backgroundColor: context.iosTokens.background,
      body: navigationShell,
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final floating = constraints.maxWidth >= 760;
          final bar = NokhchiinTabBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => _onTap(context, index, config),
            accent: accent,
            floating: floating,
            labels: config.labels,
            iconAssets: config.iconAssets,
          );
          if (!floating) return bar;
          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: bar,
              ),
            ),
          );
        },
      ),
    );
  }
}
