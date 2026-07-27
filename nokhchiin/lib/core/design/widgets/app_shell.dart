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
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final floating = constraints.maxWidth >= 760;
          final bar = NokhchiinTabBar(
            currentIndex: navigationShell.currentIndex,
            onTap: _onTap,
            accent: accent,
            floating: floating,
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
