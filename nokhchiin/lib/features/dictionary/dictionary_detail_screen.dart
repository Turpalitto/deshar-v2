import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/dictionary_search_providers.dart';
import '../../core/utils/dictionary_labels.dart';
import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/entry_type.dart';
import 'dictionary_card.dart';

/// Экран детали записи словаря.
///
/// Большой заголовок, перевод, категория, источники, связанные записи,
/// favorite, copy.
class DictionaryDetailScreen extends ConsumerWidget {
  const DictionaryDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(dictionaryEntryProvider(id));
    final related = ref.watch(dictionaryRelatedProvider(id));
    final e = entry.valueOrNull;

    // Единый шелл AppScaffold вместо голого Scaffold+SliverAppBar — раньше
    // в приложении было 4 несовместимых системы шапки экрана (аудит §3/§8).
    return AppScaffold(
      actions: e == null
          ? null
          : [
              IconButton(
                icon: Icon(
                  e.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: e.favorite ? Colors.redAccent : null,
                ),
                onPressed: () => ref.read(dictionarySearchRepoProvider).toggleFavorite(e.id),
                tooltip: 'Избранное',
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Копировать',
                onPressed: () => _onCopy(context, e),
              ),
            ],
      body: entry.when(
        data: (e) => e == null
            ? _NotFound(onBack: () => context.pop())
            : _DetailContent(entry: e, related: related.valueOrNull ?? const []),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _NotFound(onBack: () => context.pop()),
      ),
    );
  }

  void _onCopy(BuildContext context, DictionaryEntry entry) {
    Clipboard.setData(ClipboardData(text: '${entry.chechen} — ${entry.russian}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Скопировано'), duration: Duration(seconds: 1)),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.entry, required this.related});

  final DictionaryEntry entry;
  final List<DictionaryEntry> related;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final categoryLabel = DictionaryLabels.categoryLabel(entry.category, sources: entry.sources);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Бейдж типа
          _TypeBadge(type: entry.type),
          const SizedBox(height: 16),
          // Большой заголовок — чеченский
          Text(
            entry.chechen,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
              letterSpacing: 0.3,
              height: 1.2,
            ),
          ),
          if (entry.pronunciation != null) ...[
            const SizedBox(height: 8),
            Text(
              '[${entry.pronunciation}]',
              style: TextStyle(fontSize: 15, color: tokens.textTertiary),
            ),
          ],
          const SizedBox(height: 20),
          // Перевод
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.separator),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Перевод',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tokens.textTertiary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.russian,
                  style: TextStyle(
                    fontSize: 18,
                    color: tokens.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Категория
          if (categoryLabel != null) ...[
            const SizedBox(height: 20),
            _Row(label: 'Категория', value: categoryLabel),
          ],
          // Источники
          if (entry.sources.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Row(label: 'Источник', value: entry.sources.join(', ')),
          ],
          // Примеры (пока пусто — TODO из датасета)
          // Связанные
          if (related.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              'Связанные',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...related.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RelatedRow(
                    entry: r,
                    onTap: () => context.push('/dictionary/${r.id}'),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final EntryType type;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final color = switch (type) {
      EntryType.word => tokens.accent,
      EntryType.phrase => const Color(0xFF3D7A5C),
      EntryType.idiom => const Color(0xFFC4724E),
      EntryType.expression => const Color(0xFFD4A84B),
      EntryType.sentence => const Color(0xFF6B7280),
      EntryType.unknown => tokens.textTertiary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(type.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.textTertiary),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: tokens.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _RelatedRow extends StatelessWidget {
  const _RelatedRow({required this.entry, required this.onTap});
  final DictionaryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DictionaryCard(entry: entry, onTap: onTap, onFavorite: () {});
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Запись не найдена', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          TextButton(onPressed: onBack, child: const Text('Назад')),
        ],
      ),
    );
  }
}
