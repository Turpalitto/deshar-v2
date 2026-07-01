import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../tokens/app_spacing.dart';

/// Нижняя навигация: Главная · Миры · Повтор · Профиль.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.public_rounded), label: 'Миры'),
          NavigationDestination(icon: Icon(Icons.autorenew_rounded), label: 'Повтор'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Профиль'),
        ],
        indicatorColor: cs.primary.withValues(alpha: 0.15),
      ),
    );
  }
}
