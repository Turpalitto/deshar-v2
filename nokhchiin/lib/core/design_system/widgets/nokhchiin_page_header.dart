import 'package:flutter/material.dart';
import '../design_system.dart';

/// Заголовок экрана с кнопкой «назад» (Figma Make).
class NokhchiinPageHeader extends StatelessWidget {
  const NokhchiinPageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final canPop = onBack != null || Navigator.canPop(context);

    return Row(
      children: [
        if (canPop)
          IconButton(
            onPressed: onBack ?? () => Navigator.maybePop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: tokens.textTertiary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        if (canPop) const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
