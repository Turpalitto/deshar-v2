import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokhchiin/core/l10n/l10n_extensions.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/feature_flags.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/tokens/app_typography.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/error_state.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dict = ref.watch(dictionaryProvider);
    final profile = ref.watch(userProfileProvider).value;
    final isPremium = profile?.isPremium ?? false;

    return AppScaffold(
      title: l10n.dictionaryTitle,
      body: Column(
        children: [
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: AppCard(
                onTap: () => context.push('/paywall?return=/dictionary'),
                child: Text(
                  'Free: ${SubscriptionLimits.freeDictionaryBrowseLimit} слов · Premium — весь словарь',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: l10n.dictionarySearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
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
                        .where((w) =>
                            w.chechen.toLowerCase().contains(_query.toLowerCase()) ||
                            w.russian.toLowerCase().contains(_query.toLowerCase()))
                        .take(searchLimit)
                        .toList();
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: filtered.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text(
                          l10n.dictionaryMeta(words.length),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }
                    return _WordTile(
                      word: filtered[i - 1],
                      audioEnabled: FeatureFlags.audioEnabled,
                      verifiedLabel: l10n.verifiedLabel,
                      onSpeak: FeatureFlags.audioEnabled
                          ? () => ref.read(_audioProvider).speakChechen(filtered[i - 1].chechen)
                          : () {},
                      onFavorite: () =>
                          ref.read(progressRepoProvider).toggleFavorite(filtered[i - 1].id),
                    );
                  },
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

class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.word,
    required this.onSpeak,
    required this.onFavorite,
    required this.verifiedLabel,
    this.audioEnabled = false,
  });

  final WordEntity word;
  final VoidCallback onSpeak;
  final VoidCallback onFavorite;
  final String verifiedLabel;
  final bool audioEnabled;

  @override
  Widget build(BuildContext context) {
    final verified = word.tags.contains('verified') || word.sources.contains('curated');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: audioEnabled ? onSpeak : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(word.emoji ?? '📖', style: const TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word.chechen, style: AppTypography.chechenWord(context)),
                  Text(word.russian, style: Theme.of(context).textTheme.bodyLarge),
                  if (word.pronunciation != null && word.pronunciation!.isNotEmpty)
                    Text(word.pronunciation!, style: AppTypography.pronunciation(context)),
                  if (verified)
                    Text(
                      verifiedLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite_border_rounded),
              onPressed: onFavorite,
            ),
            if (audioEnabled)
              IconButton(icon: const Icon(Icons.volume_up_rounded), onPressed: onSpeak),
          ],
        ),
      ),
    );
  }
}
