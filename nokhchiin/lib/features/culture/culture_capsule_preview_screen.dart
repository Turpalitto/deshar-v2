import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/culture_capsule.dart';
import 'culture_capsule_modal.dart';

/// Dev-экран: ручной просмотр культурных капсул. Не подключён к флоу юнитов.
class CultureCapsulePreviewScreen extends ConsumerWidget {
  const CultureCapsulePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsules = ref.watch(_allCapsulesProvider);

    // Единый шелл AppScaffold вместо CupertinoPageScaffold — раньше в
    // приложении было 4 несовместимых системы шапки экрана (аудит §3/§8).
    // Заодно название по-русски — раньше был единственный англоязычный
    // экран во всём приложении (аудит §3).
    return AppScaffold(
      title: 'Культурные капсулы (dev)',
      body: capsules.when(
        data: (list) => ListView.separated(
          padding: const EdgeInsets.all(IosSpacing.screenHorizontal),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: IosSpacing.x3),
          itemBuilder: (context, index) {
            final capsule = list[index];
            return _PreviewTile(
              capsule: capsule,
              onTap: () => CultureCapsuleModal.show(context, capsule),
            );
          },
        ),
        loading: () => const LoadingState(),
        error: (_, __) => const Center(child: Text('Не удалось загрузить капсулы')),
      ),
    );
  }
}

final _allCapsulesProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(cultureCapsuleRepoProvider).getAll(),
);

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
