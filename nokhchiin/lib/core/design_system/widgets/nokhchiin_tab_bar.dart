import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system.dart';

/// iOS tab bar из Figma — Главная · Миры · Повтор · Профиль.
class NokhchiinTabBar extends StatelessWidget {
  const NokhchiinTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.accent,
    this.floating = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? accent;
  final bool floating;

  static const _labels = ['Главная', 'Миры', 'Повтор', 'Профиль'];

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final active = accent ?? tokens.accent;

    return Container(
      decoration: BoxDecoration(
        color: tokens.backgroundElevated,
        border: floating
            ? Border.all(color: tokens.separator, width: 0.7)
            : Border(top: BorderSide(color: tokens.separator, width: 0.5)),
        borderRadius: floating ? BorderRadius.circular(24) : null,
        boxShadow: floating
            ? [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: tokens.isDark ? 0.32 : 0.10,
                  ),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.only(top: 8, bottom: floating ? 9 : 20),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = currentIndex == i;
          final iconColor = isActive ? active : tokens.textTertiary;
          return Expanded(
            child: Semantics(
              button: true,
              selected: isActive,
              label: _labels[i],
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(i);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Активная вкладка — иконка в тонированной пилюле:
                    // индикатор текущего экрана, а не только цвет.
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: const Cubic(0.32, 0.72, 0, 1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? active.withValues(
                                alpha: tokens.isDark ? 0.22 : 0.12,
                              )
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: AppTabIcon(index: i, color: iconColor),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w600,
                        letterSpacing: 0.2,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
