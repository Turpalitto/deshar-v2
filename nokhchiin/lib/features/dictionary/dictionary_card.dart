import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/entry_type.dart';

class DictionaryCard extends StatelessWidget {
  const DictionaryCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onFavorite,
  });

  final DictionaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final color = _typeColor(entry.type, tokens);

    return Semantics(
      button: true,
      label: '${entry.chechen} — ${entry.russian}. ${entry.type.label}',
      child: Material(
        color: tokens.surface,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: tokens.isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SizedBox.square(
                      dimension: 40,
                      child: Icon(
                        _typeIcon(entry.type),
                        color: color,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.russian,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.type != EntryType.word &&
                      entry.type != EntryType.unknown)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        entry.type.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      entry.favorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                      color: entry.favorite
                          ? tokens.error
                          : tokens.textTertiary,
                    ),
                    onPressed: onFavorite,
                    tooltip: entry.favorite
                        ? 'Удалить из избранного'
                        : 'Добавить в избранное',
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _typeIcon(EntryType type) => switch (type) {
  EntryType.word => Icons.text_fields_rounded,
  EntryType.phrase => Icons.format_quote_rounded,
  EntryType.idiom => Icons.forum_outlined,
  EntryType.expression => Icons.translate_rounded,
  EntryType.sentence => Icons.subject_rounded,
  EntryType.unknown => Icons.help_outline_rounded,
};

Color _typeColor(EntryType type, DesignTokens tokens) => switch (type) {
  EntryType.word => DesignTokens.meadow,
  EntryType.phrase => DesignTokens.terracotta,
  EntryType.idiom => DesignTokens.coral,
  EntryType.expression => DesignTokens.gold,
  EntryType.sentence => DesignTokens.sky,
  EntryType.unknown => tokens.textTertiary,
};
