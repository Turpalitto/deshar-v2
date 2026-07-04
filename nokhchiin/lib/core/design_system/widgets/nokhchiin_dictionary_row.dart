import 'package:flutter/material.dart';
import '../../design/widgets/app_icon_image.dart';
import '../design_system.dart';

/// Строка словаря (Figma Make).
class NokhchiinDictionaryRow extends StatelessWidget {
  const NokhchiinDictionaryRow({
    super.key,
    this.emoji,
    this.iconAsset,
    required this.chechen,
    required this.russian,
    this.transcription,
    this.category,
    this.nounClassMarker,
    this.onTap,
    this.trailing,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String chechen;
  final String russian;
  final String? transcription;
  final String? category;
  final String? nounClassMarker;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final meta = [
      if (nounClassMarker != null) nounClassMarker!,
      if (transcription != null && transcription!.isNotEmpty) '[$transcription]',
      if (category != null && category!.isNotEmpty) category,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: iconAsset != null
                  ? AppIconImage(asset: iconAsset!, size: 22, color: tokens.accent)
                  : Text(emoji!, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chechen,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (meta.isNotEmpty)
                    Text(
                      meta,
                      style: TextStyle(fontSize: 12, color: tokens.textTertiary),
                    ),
                ],
              ),
            ),
            Text(
              russian,
              style: TextStyle(
                fontSize: 15,
                color: tokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
