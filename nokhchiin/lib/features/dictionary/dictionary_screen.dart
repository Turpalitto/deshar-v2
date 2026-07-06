import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/l10n/l10n_extensions.dart';
import '../../core/providers/dictionary_search_providers.dart';
import '../../core/utils/number_format.dart';
import 'dictionary_card.dart';

/// Переработанный экран словаря — Apple Dictionary style.
///
/// Header + search + filter chips + virtualized list.
/// UI получает только [DictionaryEntry] — никогда сырой JSON.
class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(dictionarySearchProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(dictionaryQueryProvider.notifier).state = value;
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  void _onFilterChanged(DictionaryFilter filter) {
    ref.read(dictionaryFilterProvider.notifier).state = filter;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.iosTokens;
    final result = ref.watch(dictionarySearchProvider);
    final totalCount = ref.watch(dictionaryTotalCountProvider).valueOrNull ?? 0;
    final currentFilter = ref.watch(dictionaryFilterProvider);

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => context.pop(),
                        padding: EdgeInsets.zero,
                        // HIG-минимум 44×44 (аудит §3).
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.dictionaryTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      if (totalCount > 0)
                        Text(
                          '${formatThousands(totalCount)} '
                          '${pluralize(totalCount, one: 'слово', few: 'слова', many: 'слов')}',
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Search
                  Container(
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tokens.separator),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(fontSize: 15, color: tokens.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n.dictionarySearchHint,
                        hintStyle: TextStyle(color: tokens.textTertiary, fontSize: 15),
                        prefixIcon: Icon(Icons.search_rounded, color: tokens.textTertiary, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Filter chips
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: DictionaryFilter.values.map((f) {
                  final selected = f == currentFilter;
                  final color = _filterColor(f, tokens);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.label),
                      selected: selected,
                      onSelected: (_) => _onFilterChanged(f),
                      selectedColor: color.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? color : tokens.textSecondary,
                      ),
                      backgroundColor: tokens.surface,
                      side: BorderSide(color: selected ? color.withValues(alpha: 0.3) : tokens.separator),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // List
            Expanded(
              child: result.when(
                data: (data) {
                  if (data.entries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: tokens.textTertiary),
                          const SizedBox(height: 12),
                          Text(
                            'Ничего не найдено',
                            style: TextStyle(fontSize: 15, color: tokens.textTertiary),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: data.entries.length + (data.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= data.entries.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      final entry = data.entries[i];
                      return DictionaryCard(
                        entry: entry,
                        onTap: () => context.push('/dictionary/${entry.id}'),
                        onFavorite: () =>
                            ref.read(dictionarySearchProvider.notifier).toggleFavorite(entry.id),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Ошибка загрузки'),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(dictionarySearchProvider);
                          ref.invalidate(dictionaryTotalCountProvider);
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _filterColor(DictionaryFilter f, DesignTokens tokens) {
    return switch (f) {
      DictionaryFilter.all => tokens.accent,
      DictionaryFilter.words => const Color(0xFF1B6B4A),
      DictionaryFilter.phrases => const Color(0xFF3D7A5C),
      DictionaryFilter.sentences => const Color(0xFF6B7280),
      DictionaryFilter.favorites => Colors.redAccent,
    };
  }
}
