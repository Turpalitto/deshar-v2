import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/chechen_audio_service.dart';

final chechenAudioServiceProvider = Provider<ChechenAudioService>(
  (_) => ChechenAudioService(),
);

final audioAvailabilityProvider = FutureProvider.family<bool, String?>((
  ref,
  audioId,
) {
  return ref.watch(chechenAudioServiceProvider).hasVerifiedClip(audioId);
});
