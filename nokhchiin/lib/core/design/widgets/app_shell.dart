import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/design_system.dart';
import '../../providers/providers.dart';
import '../../../domain/entities/enums.dart';

/// Нижняя навигация в стиле Figma Make.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final isKids = profile?.mode == AppMode.kids;
    final accent = isKids ? DesignTokens.meadow : context.iosTokens.accent;

    return Scaffold(
      backgroundColor: context.iosTokens.background,
      body: navigationShell,
      bottomNavigationBar: NokhchiinTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        accent: accent,
      ),
    );
  }
}
