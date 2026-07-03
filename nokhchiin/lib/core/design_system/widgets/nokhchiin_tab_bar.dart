import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/widgets/app_icon_image.dart';
import '../design_system.dart';

/// iOS tab bar из Figma — Главная · Миры · Повтор · Профиль.
class NokhchiinTabBar extends StatelessWidget {
  const NokhchiinTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.accent,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? accent;

  static const _labels = ['Главная', 'Миры', 'Повтор', 'Профиль'];

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final active = accent ?? tokens.accent;

    return Container(
      decoration: BoxDecoration(
        color: tokens.backgroundElevated,
        border: Border(top: BorderSide(color: tokens.separator, width: 0.5)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 20),
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
                  AppTabIcon(index: i, color: iconColor),
                  const SizedBox(height: 2),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
