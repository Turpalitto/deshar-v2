import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/l10n/l10n_extensions.dart';
import '../../core/providers/dictionary_search_providers.dart';
import '../../core/utils/number_format.dart';
import 'dictionary_card.dart';

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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

  void _resetSearch() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(dictionaryQueryProvider.notifier).state = '';
    ref.read(dictionaryFilterProvider.notifier).state = DictionaryFilter.all;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.iosTokens;
    final result = ref.watch(dictionarySearchProvider);
    final totalCount = ref.watch(dictionaryTotalCountProvider).valueOrNull ?? 0;
    final currentFilter = ref.watch(dictionaryFilterProvider);
    final scope = ref.watch(dictionaryScopeProvider);
    final query = ref.watch(dictionaryQueryProvider);
    final visibleCount = result.valueOrNull?.totalCount ?? totalCount;

    return AppScaffold(
      title: l10n.dictionaryTitle,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: CupertinoSlidingSegmentedControl<DictionaryScope>(
              groupValue: scope,
              backgroundColor: tokens.surfaceMuted,
              thumbColor: tokens.surface,
              padding: const EdgeInsets.all(3),
              children: const {
                DictionaryScope.core: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  child: Text('Основной'),
                ),
                DictionaryScope.full: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  child: Text('Все записи'),
                ),
              },
              onValueChanged: (value) {
                if (value == null) return;
                ref.read(dictionaryScopeProvider.notifier).state = value;
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(0);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: CupertinoSearchTextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSuffixTap: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              placeholder: l10n.dictionarySearchHint,
              backgroundColor: tokens.surfaceMuted,
              itemColor: tokens.textTertiary,
              style: TextStyle(color: tokens.textPrimary, fontSize: 15),
              placeholderStyle: TextStyle(
                color: tokens.textTertiary,
                fontSize: 15,
              ),
              borderRadius: BorderRadius.circular(8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: DictionaryFilter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = DictionaryFilter.values[index];
                return _FilterPill(
                  label: filter.label,
                  selected: filter == currentFilter,
                  onTap: () => _onFilterChanged(filter),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${formatThousands(visibleCount)} '
                '${pluralize(visibleCount, one: 'запись', few: 'записи', many: 'записей')}',
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: tokens.surface),
                  child: result.when(
                    data: (data) {
                      if (data.entries.isEmpty) {
                        return NokhchiinEmptyState(
                          iconAsset: 'assets/icons/state_empty.svg',
                          title: query.trim().isEmpty
                              ? 'В этом разделе пока нет записей'
                              : 'Ничего не найдено',
                          subtitle: query.trim().isEmpty
                              ? 'Выберите другой тип записи.'
                              : 'Проверьте написание или сбросьте фильтры.',
                          actionLabel: 'Сбросить фильтры',
                          onAction: _resetSearch,
                        );
                      }
                      return ListView.separated(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: data.entries.length + (data.hasMore ? 1 : 0),
                        separatorBuilder: (_, index) => Divider(
                          height: 1,
                          indent: index < data.entries.length ? 64 : 0,
                          color: tokens.separator,
                        ),
                        itemBuilder: (context, index) {
                          if (index >= data.entries.length) {
                            return const SizedBox(
                              height: 64,
                              child: Center(
                                child: CupertinoActivityIndicator(),
                              ),
                            );
                          }
                          final entry = data.entries[index];
                          return DictionaryCard(
                            entry: entry,
                            onTap: () =>
                                context.push('/dictionary/${entry.id}'),
                            onFavorite: () => ref
                                .read(dictionarySearchProvider.notifier)
                                .toggleFavorite(entry.id),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CupertinoActivityIndicator(radius: 12),
                    ),
                    error: (_, _) => NokhchiinErrorState(
                      message: 'Не удалось загрузить словарь',
                      onRetry: () {
                        ref.invalidate(dictionarySearchProvider);
                        ref.invalidate(dictionaryTotalCountProvider);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    return Material(
      color: selected ? tokens.accent : tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? tokens.accent : tokens.separator),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? tokens.accentOn : tokens.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
