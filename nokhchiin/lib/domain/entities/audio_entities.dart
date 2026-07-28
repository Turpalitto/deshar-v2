import 'package:equatable/equatable.dart';

enum AudioSpeed { normal, slow }

class NativeAudioClip extends Equatable {
  const NativeAudioClip({
    required this.id,
    required this.speakerId,
    required this.dialect,
    required this.durationMs,
    required this.version,
    required this.sha256,
    required this.languageTag,
    required this.license,
    this.assetPath,
    this.remotePath,
    this.packId = 'base',
    this.speed = AudioSpeed.normal,
  });

  final String id;
  final String speakerId;
  final String dialect;
  final int durationMs;
  final int version;
  final String sha256;
  final String languageTag;
  final String license;
  final String? assetPath;
  final String? remotePath;
  final String packId;
  final AudioSpeed speed;

  @override
  List<Object?> get props => [id, version, sha256, license];
}

class AudioPack extends Equatable {
  const AudioPack({
    required this.id,
    required this.version,
    required this.bundled,
    this.downloadUrl,
    this.sha256,
    this.sizeBytes,
  });

  final String id;
  final int version;
  final bool bundled;
  final String? downloadUrl;
  final String? sha256;
  final int? sizeBytes;

  @override
  List<Object?> get props => [id, version];
}

class AudioSpeaker extends Equatable {
  const AudioSpeaker({
    required this.id,
    required this.displayName,
    required this.dialect,
    required this.consentRef,
  });

  final String id;
  final String displayName;
  final String dialect;
  final String consentRef;

  @override
  List<Object?> get props => [id, displayName, dialect, consentRef];
}

class AudioCatalog extends Equatable {
  const AudioCatalog({
    required this.schemaVersion,
    required this.basePack,
    required this.downloadablePacks,
    required this.speakers,
    required this.clips,
  });

  final int schemaVersion;
  final AudioPack basePack;
  final List<AudioPack> downloadablePacks;
  final List<AudioSpeaker> speakers;
  final Map<String, NativeAudioClip> clips;

  Iterable<AudioPack> get packs sync* {
    yield basePack;
    yield* downloadablePacks;
  }

  @override
  List<Object?> get props => [
    schemaVersion,
    basePack,
    downloadablePacks,
    speakers,
    clips,
  ];
}
