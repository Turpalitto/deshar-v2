import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/analytics_service.dart';
import '../../domain/entities/analytics_event.dart';
import '../services/chechen_audio_service.dart';

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
          onPressed: () async {
            final result = await service.play(audioId);
            if (result == AudioActionResult.played) {
              await _trackAudio(ref, AnalyticsEventName.audioPlayed, audioId);
            }
          },
          icon: const Icon(Icons.volume_up_outlined),
        ),
        IconButton.filledTonal(
          tooltip: 'Записать мой голос',
          onPressed: service.canRecordVoice
              ? () async {
                  final path = await service.recordUserVoice(
                    referenceAudioId: audioId,
                  );
                  if (path != null) {
                    await _trackAudio(
                      ref,
                      AnalyticsEventName.voiceRecorded,
                      audioId,
                    );
                  }
                }
              : null,
          icon: const Icon(Icons.mic_none_outlined),
        ),
      ],
    );
  }
}

Future<void> _trackAudio(
  WidgetRef ref,
  AnalyticsEventName event,
  String? audioId,
) async {
  try {
    await ref
        .read(analyticsServiceProvider)
        .track(
          event,
          properties: audioId == null ? const {} : {'audio_id': audioId},
        );
  } catch (_) {
    // Audio playback and recording stay usable if analytics is unavailable.
  }
}
