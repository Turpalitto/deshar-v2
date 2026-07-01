import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/widgets/app_button.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/word_entity.dart';

final _rng = Random();

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({
    super.key,
    required this.unitId,
    this.embedded = false,
    this.onComplete,
  });
  final String unitId;
  final bool embedded;
  final VoidCallback? onComplete;

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  List<WordEntity> _words = [];
  String? _selCe;
  String? _selRu;
  final _matched = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var words = await ref.read(dictionaryRepoProvider).getWordsByCategory(widget.unitId);
    if (words.length < 4) {
      words = (await ref.read(dictionaryRepoProvider).getAllWords()).take(5).toList();
    }
    if (mounted) {
      setState(() {
        _words = words.take(5).toList();
        _loading = false;
      });
    }
  }

  void _tapCe(String id) => setState(() => _selCe = id);
  void _tapRu(String id) => setState(() => _selRu = id);

  Future<void> _check() async {
    if (_selCe == null || _selRu == null) return;
    if (_selCe == _selRu) {
      _matched.add(_selCe!);
      await ref.read(reviewWordUseCaseProvider)(_selCe!, 4);
    }
    setState(() {
      _selCe = null;
      _selRu = null;
    });
    if (_matched.length == _words.length && mounted) {
      if (widget.embedded) {
        widget.onComplete?.call();
      } else {
        await ref.read(userProfileProvider.notifier).addXp(60, 6);
        if (mounted) context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.embedded
          ? const Center(child: LoadingState())
          : const AppScaffold(body: LoadingState());
    }
    if (_words.isEmpty) {
      return const Center(child: Text('Недостаточно слов'));
    }

    final ruList = [..._words]..shuffle(_rng);
    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'Собери пары ${_matched.length}/${_words.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    children: _words
                        .map((w) => _MatchBtn(
                              label: w.chechen,
                              emoji: w.emoji,
                              selected: _selCe == w.id,
                              matched: _matched.contains(w.id),
                              onTap: () => _tapCe(w.id),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ListView(
                    children: ruList
                        .map((w) => _MatchBtn(
                              label: w.russian,
                              emoji: null,
                              selected: _selRu == w.id,
                              matched: _matched.contains(w.id),
                              onTap: () => _tapRu(w.id),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          AppButton(label: 'Проверить', onPressed: _check),
        ],
      ),
    );

    if (widget.embedded) return body;
    return AppScaffold(title: 'Пары', body: body);
  }
}

class _MatchBtn extends StatelessWidget {
  const _MatchBtn({
    required this.label,
    required this.selected,
    required this.matched,
    required this.onTap,
    this.emoji,
  });

  final String label;
  final String? emoji;
  final bool selected, matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: matched ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: selected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
            color: matched ? Colors.green.withValues(alpha: 0.15) : null,
          ),
          child: Row(
            children: [
              if (emoji != null) Text(emoji!, style: const TextStyle(fontSize: 20)),
              if (emoji != null) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    decoration: matched ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
