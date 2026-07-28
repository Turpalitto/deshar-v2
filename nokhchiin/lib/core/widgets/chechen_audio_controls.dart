import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

class ChechenAudioControls extends ConsumerWidget {
  const ChechenAudioControls({
    super.key,
    required this.audioId,
    this.compact = false,
  });

  final String? audioId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(audioAvailabilityProvider(audioId));
    final hasAudio = available.valueOrNull ?? false;
    if (!hasAudio) {
      return Semantics(
        label: 'Аудио пока недоступно',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.volume_off_outlined,
              size: compact ? 18 : 22,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 6),
            const Flexible(child: Text('Аудио пока недоступно')),
          ],
        ),
      );
    }

    final service = ref.read(chechenAudioServiceProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        IconButton.filledTonal(
          tooltip: 'Эталонная запись',
          onPressed: () => service.play(audioId),
          icon: const Icon(Icons.volume_up_outlined),
        ),
        IconButton.filledTonal(
          tooltip: 'Записать мой голос',
          onPressed: service.canRecordVoice
              ? () => service.recordUserVoice(referenceAudioId: audioId)
              : null,
          icon: const Icon(Icons.mic_none_outlined),
        ),
      ],
    );
  }
}
