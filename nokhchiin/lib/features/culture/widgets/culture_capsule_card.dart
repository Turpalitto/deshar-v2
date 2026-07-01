import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';
import '../../../domain/entities/culture_capsule.dart';

/// Контент полноэкранной культурной интерлюдии.
class CultureCapsuleCard extends StatelessWidget {
  const CultureCapsuleCard({
    super.key,
    required this.capsule,
    required this.onContinue,
  });

  final CultureCapsule capsule;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final textTheme = IosTypography.of(context, tokens);
    final paragraphs = capsule.paragraphs;

    return ColoredBox(
      color: tokens.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: IosSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: IosSpacing.x8),
              Text(
                capsule.title,
                style: textTheme.displayMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: IosSpacing.x6),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (capsule.imagePath != null) ...[
                        _CapsuleImage(path: capsule.imagePath!),
                        const SizedBox(height: IosSpacing.x6),
                      ],
                      for (var i = 0; i < paragraphs.length; i++) ...[
                        if (i > 0) const SizedBox(height: IosSpacing.x5),
                        Text(
                          paragraphs[i],
                          style: textTheme.bodyLarge?.copyWith(
                            color: tokens.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: IosSpacing.x8),
                    ],
                  ),
                ),
              ),
              CupertinoButton.filled(
                borderRadius: BorderRadius.circular(14),
                color: tokens.accent,
                padding: const EdgeInsets.symmetric(vertical: IosSpacing.x4),
                onPressed: onContinue,
                child: Text(
                  'Продолжить',
                  style: textTheme.headlineSmall?.copyWith(
                    color: tokens.accentOn,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: IosSpacing.x4),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapsuleImage extends StatelessWidget {
  const _CapsuleImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: tokens.surfaceMuted,
            child: Center(
              child: Icon(Icons.image_outlined, size: 40, color: tokens.textTertiary),
            ),
          ),
        ),
      ),
    );
  }
}
