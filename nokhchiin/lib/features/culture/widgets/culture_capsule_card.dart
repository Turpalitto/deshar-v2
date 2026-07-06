import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/widgets/app_icon_image.dart';
import '../../../core/design_system/design_system.dart';
import '../../../domain/entities/culture_capsule.dart';

/// Полноэкранная культурная капсула — тёмный стиль Figma (#1E1510).
class CultureCapsuleCard extends StatelessWidget {
  const CultureCapsuleCard({
    super.key,
    required this.capsule,
    required this.onContinue,
    required this.onClose,
  });

  final CultureCapsule capsule;

  /// "Продолжить →" — пользователь реально прочитал капсулу, отмечаем как
  /// увиденную навсегда.
  final VoidCallback onContinue;

  /// "✕ Закрыть" — просто закрыть сейчас, без отметки "увидено навсегда"
  /// (аудит §3: раньше обе кнопки делали одно и то же, вопреки ожиданию от
  /// иконки закрытия — капсула больше никогда не показывалась, даже если
  /// пользователь её просто закрыл, не читая).
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final paragraphs = capsule.paragraphs;

    return ColoredBox(
      color: DesignTokens.cultureDark,
      child: Stack(
        children: [
          const Positioned.fill(
            child: NokhchiinOrnament(opacity: 0.055, light: true),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: IosSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: IosSpacing.x4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onClose,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        foregroundColor: Colors.white.withValues(alpha: 0.65),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('✕ Закрыть', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(height: IosSpacing.x6),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'АДАТ · КУЛЬТУРА',
                            style: TextStyle(
                              fontSize: 11,
                              color: DesignTokens.cultureAccent,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: IosSpacing.x3),
                          Text(
                            capsule.title,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF5F0E8),
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: IosSpacing.x6),
                          _CapsuleIllustration(imagePath: capsule.imagePath),
                          const SizedBox(height: IosSpacing.x6),
                          for (var i = 0; i < paragraphs.length; i++) ...[
                            if (i > 0) const SizedBox(height: IosSpacing.x4),
                            Text(
                              paragraphs[i],
                              style: TextStyle(
                                fontSize: i == 0 ? 16 : 15,
                                color: Color(0xFFF5F0E8).withValues(alpha: i == 0 ? 0.85 : 0.6),
                                height: 1.65,
                              ),
                            ),
                          ],
                          const SizedBox(height: IosSpacing.x6),
                          Row(
                            children: [
                              _FactChip(iconAsset: AppIcons.cultureHandshake, label: 'Уважение'),
                              const SizedBox(width: 10),
                              _FactChip(iconAsset: AppIcons.cultureFeast, label: 'Стол'),
                              const SizedBox(width: 10),
                              _FactChip(iconAsset: AppIcons.cultureMountains, label: 'Нохчалла'),
                            ],
                          ),
                          const SizedBox(height: IosSpacing.x6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: DesignTokens.cultureAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: DesignTokens.cultureAccent.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'СЛОВО ИЗ КАПСУЛЫ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: DesignTokens.cultureAccent,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Хьаша',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFF5F0E8),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Гость · [khyasha]',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0x80F5F0E8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: IosSpacing.x8),
                        ],
                      ),
                    ),
                  ),
                  NokhchiinButton(
                    label: 'Продолжить →',
                    fullWidth: true,
                    onPressed: onContinue,
                  ),
                  const SizedBox(height: IosSpacing.x4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapsuleIllustration extends StatelessWidget {
  const _CapsuleIllustration({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    // Декодируем под реальный размер контейнера (180pt высотой), а не в
    // исходном разрешении картинки (2560×2160) — раньше не было ни одного
    // cacheWidth/cacheHeight во всём приложении (аудит §4).
    final cacheHeight = (180 * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: imagePath != null
            ? Image.asset(imagePath!, fit: BoxFit.cover, cacheHeight: cacheHeight)
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF5C3D2E), Color(0xFF8B5E3C), Color(0xFF6B4423)],
                  ),
                ),
                alignment: Alignment.center,
                child: const AppIconImage(asset: AppIcons.cultureHeritage, size: 72),
              ),
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({
    this.emoji,
    this.iconAsset,
    required this.label,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            if (iconAsset != null)
              AppIconImage(asset: iconAsset!, size: 24)
            else
              Text(emoji!, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
