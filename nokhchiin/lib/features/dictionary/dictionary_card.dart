import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../domain/entities/dictionary_entry.dart';
import '../../domain/entities/entry_type.dart';

/// Карточка записи словаря — Apple Dictionary style.
///
/// Минимальная, элегантная. Не перегружена. Иконка типа, чеченский,
/// перевод, бейдж типа, кнопка избранного. Никакого сырого текста.
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

    return Semantics(
      button: true,
      label: '${entry.chechen} — ${entry.russian}. ${entry.type.label}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Иконка типа
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _typeColor(entry.type, tokens).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(entry.type.emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 14),
                // Текст
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        entry.russian,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Бейдж типа (только не word — для слов не показываем)
                if (entry.type != EntryType.word && entry.type != EntryType.unknown)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _typeColor(entry.type, tokens).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.type.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _typeColor(entry.type, tokens),
                      ),
                    ),
                  ),
                // Favorite
                IconButton(
                  icon: Icon(
                    entry.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 18,
                    color: entry.favorite ? Colors.redAccent : tokens.textTertiary,
                  ),
                  onPressed: onFavorite,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Избранное',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(EntryType type, DesignTokens tokens) {
    return switch (type) {
      EntryType.word => tokens.accent,
      EntryType.phrase => const Color(0xFF3D7A5C),
      EntryType.idiom => const Color(0xFFC4724E),
      EntryType.expression => const Color(0xFFD4A84B),
      EntryType.sentence => const Color(0xFF6B7280),
      EntryType.unknown => tokens.textTertiary,
    };
  }
}
