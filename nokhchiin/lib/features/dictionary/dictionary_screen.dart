import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokhchiin/core/l10n/l10n_extensions.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/feature_flags.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_scaffold.dart'; // intentional-mix: app shell scaffold
import '../../core/design/widgets/error_state.dart'; // intentional-mix: error fallback UI
import '../../core/design/widgets/loading_state.dart'; // intentional-mix: shared loading placeholder
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';
import '../../core/utils/chechen_text_utils.dart';
import '../../core/utils/dictionary_labels.dart';
import '../../domain/constants/subscription_limits.dart';
import '../../domain/entities/word_entity.dart';

final _audioProvider = Provider((_) => AudioService());

class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  String _query = '';
  final _controller = TextEditingController();
  // Debounce поиска — аудит §3.3: раньше setState на каждый keystroke →
  // линейный scan по 728КБ словаря 6 раз подряд при вводе 6-буквенного слова.
  Timer? _debounce;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dict = ref.watch(dictionaryProvider);
    final profile = ref.watch(userProfileProvider).value;
    final isPremium = FeatureFlags.premiumEnabled ? (profile?.isPremium ?? false) : true;
    final tokens = context.iosTokens;
    final wordCount = dict.maybeWhen(data: (words) => words.length, orElse: () => null);

    return AppScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: [
                NokhchiinPageHeader(
                  title: l10n.dictionaryTitle,
                  onBack: () => context.pop(),
                  trailing: wordCount == null
                      ? null
                      : NokhchiinChip(
                          label: '${_formatCount(wordCount)} слов',
                          color: tokens.textTertiary,
                          background: tokens.surfaceMuted,
                        ),
                ),
                if (FeatureFlags.premiumEnabled && !isPremium) ...[
                  const SizedBox(height: 12),
                  NokhchiinSurfaceCard(
                    onTap: () => context.push('/paywall?return=/dictionary'),
                    child: Text(
                      'Free: ${SubscriptionLimits.freeDictionaryBrowseLimit} слов · Premium — весь словарь',
                      style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                NokhchiinSearchField(
                  controller: _controller,
                  hintText: l10n.dictionarySearchHint,
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),
          Expanded(
            child: dict.when(
              data: (words) {
                final browseLimit = isPremium ? words.length : SubscriptionLimits.freeDictionaryBrowseLimit;
                final searchLimit = isPremium ? words.length : SubscriptionLimits.freeDictionarySearchLimit;
                final filtered = _query.isEmpty
                    ? words.take(browseLimit).toList()
                    : words
                        .where((w) => ChechenTextUtils.matchesWordQuery(
                              query: _query,
                              chechen: w.chechen,
                              russian: w.russian,
                            ))
                        .take(searchLimit)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Ничего не найдено',
                      style: TextStyle(fontSize: 15, color: tokens.textTertiary),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: tokens.separator),
                  itemBuilder: (context, i) => _WordRow(
                    word: filtered[i],
                    audioEnabled: FeatureFlags.audioEnabled,
                    onSpeak: FeatureFlags.audioEnabled
                        ? () => ref.read(_audioProvider).speakChechen(filtered[i].chechen)
                        : null,
                    onFavorite: () => ref.read(progressRepoProvider).toggleFavorite(filtered[i].id),
                  ),
                );
              },
              loading: () => LoadingState(message: l10n.loading),
              error: (e, _) => ErrorState(message: '$e', onRetry: () => ref.invalidate(dictionaryProvider)),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCount(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.word,
    required this.onFavorite,
    this.onSpeak,
    this.audioEnabled = false,
  });

  final WordEntity word;
  final VoidCallback onFavorite;
  final VoidCallback? onSpeak;
  final bool audioEnabled;

  @override
  Widget build(BuildContext context) {
    return NokhchiinDictionaryRow(
      emoji: word.emoji,
      iconAsset: word.emoji == null ? AppIcons.navDictionary : null,
      chechen: word.chechen,
      russian: word.russian,
      transcription: DictionaryLabels.displayTranscription(word.chechen, word.pronunciation),
      category: DictionaryLabels.categoryLabel(word.category, sources: word.sources),
      nounClassMarker: word.nounClass?.marker,
      onTap: onSpeak,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded, size: 20),
            onPressed: onFavorite,
            visualDensity: VisualDensity.compact,
          ),
          if (audioEnabled && onSpeak != null)
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, size: 20),
              onPressed: onSpeak,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
