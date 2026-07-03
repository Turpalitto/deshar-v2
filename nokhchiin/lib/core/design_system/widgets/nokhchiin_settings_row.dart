import 'package:flutter/material.dart';
import '../../design/widgets/app_icon_image.dart';
import '../design_system.dart';

/// Строка настроек профиля (Figma Make).
class NokhchiinSettingsRow extends StatelessWidget {
  const NokhchiinSettingsRow({
    super.key,
    this.emoji,
    this.iconAsset,
    required this.label,
    this.onTap,
    this.trailing,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return Semantics(
      button: onTap != null,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              if (iconAsset != null)
                AppIconImage(asset: iconAsset!, size: 20, color: tokens.accent)
              else
                Text(emoji!, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 15, color: tokens.textPrimary),
                ),
              ),
              trailing ??
                  Icon(Icons.chevron_right_rounded, color: tokens.textTertiary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
