import 'package:flutter/material.dart';
import '../../design/widgets/app_icon_image.dart';
import '../design_system.dart';

/// Плитка «Капсула / Подарок / Словарь» на главной (Figma Make).
class NokhchiinGiftTile extends StatelessWidget {
  const NokhchiinGiftTile({
    super.key,
    this.emoji,
    this.iconAsset,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.gradient,
    this.lightText = false,
    this.semanticLabel,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool lightText;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return Semantics(
      button: onTap != null,
      label: semanticLabel ?? '$title, $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? tokens.surface : null,
            borderRadius: BorderRadius.circular(18),
            border: gradient == null
                ? Border.all(color: tokens.separator)
                // Тёмная плитка в светлом ряду — не «случайная вставка», а
                // намеренный акцент: золотая волосяная обводка связывает её
                // с культурной палитрой.
                : Border.all(color: DesignTokens.gold.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3D3225).withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Иконка в тонированном сквиркле — единый паттерн со строками
              // миров и «словом дня», а не голая иконка в воздухе.
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: lightText
                      ? Colors.white.withValues(alpha: 0.14)
                      : tokens.accentMuted.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: iconAsset != null
                    ? AppIconImage(
                        asset: iconAsset!,
                        size: 18,
                        color: lightText ? DesignTokens.gold : tokens.accent,
                      )
                    : Text(emoji!, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: lightText ? Colors.white : tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: lightText ? Colors.white.withValues(alpha: 0.65) : tokens.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
