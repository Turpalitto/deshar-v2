import '../entities/audio_entities.dart';

abstract final class ChechenAudioPolicy {
  static const chechenLanguageTags = {'ce', 'ce-RU'};

  static bool isAllowed(NativeAudioClip clip) {
    return chechenLanguageTags.contains(clip.languageTag) &&
        clip.speakerId.trim().isNotEmpty &&
        clip.dialect.trim().isNotEmpty &&
        clip.durationMs > 0 &&
        clip.version > 0 &&
        clip.license.trim().isNotEmpty &&
        RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(clip.sha256) &&
        (clip.assetPath?.isNotEmpty == true ||
            clip.remotePath?.isNotEmpty == true);
  }

  static void ensureAllowed(NativeAudioClip clip) {
    if (!isAllowed(clip)) {
      throw ArgumentError.value(
        clip.languageTag,
        'languageTag',
        'Only verified native Chechen recordings are allowed',
      );
    }
  }
}
