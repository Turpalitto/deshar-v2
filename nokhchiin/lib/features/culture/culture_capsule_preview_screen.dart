import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../data/culture_capsule_samples.dart';
import '../../domain/entities/culture_capsule.dart';
import 'culture_capsule_modal.dart';

/// Dev-экран: ручной просмотр культурных капсул. Не подключён к флоу юнитов.
class CultureCapsulePreviewScreen extends StatelessWidget {
  const CultureCapsulePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final textTheme = IosTypography.of(context, tokens);

    return CupertinoPageScaffold(
      backgroundColor: tokens.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: tokens.surface.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: tokens.separator)),
        middle: Text(
          'Culture Capsules',
          style: textTheme.headlineSmall,
        ),
      ),
      child: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(IosSpacing.screenHorizontal),
          itemCount: CultureCapsuleSamples.all.length,
          separatorBuilder: (_, __) => const SizedBox(height: IosSpacing.x3),
          itemBuilder: (context, index) {
            final capsule = CultureCapsuleSamples.all[index];
            return _PreviewTile(
              capsule: capsule,
              onTap: () => CultureCapsuleModal.show(context, capsule),
            );
          },
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.capsule, required this.onTap});

  final CultureCapsule capsule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final textTheme = IosTypography.of(context, tokens);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(IosSpacing.x4),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.separator),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              capsule.title,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: IosSpacing.x1),
            Text(
              'unit: ${capsule.relatedUnitId}',
              style: textTheme.labelMedium?.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: IosSpacing.x2),
            Text(
              capsule.paragraphs.first,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
