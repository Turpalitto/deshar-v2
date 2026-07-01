import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../domain/entities/word_entity.dart';

final _rng = Random();

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key, required this.unitId});
  final String unitId;

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  List<WordEntity> _words = [];
  String? _selCe;
  String? _selRu;
  final _matched = <String>{};

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
    setState(() => _words = words.take(5).toList());
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
      await ref.read(userProfileProvider.notifier).addXp(60, 6);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final ruList = [..._words]..shuffle(_rng);
    return Scaffold(
      appBar: AppBar(title: Text('Пары ${_matched.length}/${_words.length}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: _words.map((w) => _MatchBtn(
                      label: w.chechen,
                      selected: _selCe == w.id,
                      matched: _matched.contains(w.id),
                      onTap: () => _tapCe(w.id),
                    )).toList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: ruList.map((w) => _MatchBtn(
                      label: w.russian,
                      selected: _selRu == w.id,
                      matched: _matched.contains(w.id),
                      onTap: () {
                        _tapRu(w.id);
                        _check();
                      },
                    )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchBtn extends StatelessWidget {
  const _MatchBtn({
    required this.label,
    required this.selected,
    required this.matched,
    required this.onTap,
  });
  final String label;
  final bool selected, matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: matched
            ? const Color(0xFFE6F4EA)
            : selected
                ? const Color(0xFFE8F0FE)
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: matched ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
