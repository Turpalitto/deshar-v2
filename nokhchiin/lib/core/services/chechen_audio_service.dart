import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/audio_entities.dart';
import '../../domain/services/chechen_audio_policy.dart';

enum AudioActionResult { played, unavailable }

abstract interface class NativeAudioPlaybackGateway {
  bool get isAvailable;
  Future<void> play(NativeAudioClip clip);
  Future<void> stop();
}

abstract interface class UserVoiceRecorder {
  bool get isAvailable;
  Future<String?> record();
  Future<void> play(String recordingPath);
}

class UnavailableNativeAudioPlaybackGateway
    implements NativeAudioPlaybackGateway {
  const UnavailableNativeAudioPlaybackGateway();

  @override
  bool get isAvailable => false;

  @override
  Future<void> play(NativeAudioClip clip) async {}

  @override
  Future<void> stop() async {}
}

class UnavailableUserVoiceRecorder implements UserVoiceRecorder {
  const UnavailableUserVoiceRecorder();

  @override
  bool get isAvailable => false;

  @override
  Future<void> play(String recordingPath) async {}

  @override
  Future<String?> record() async => null;
}

class ChechenAudioService {
  ChechenAudioService({
    this._playback = const UnavailableNativeAudioPlaybackGateway(),
    this._recorder = const UnavailableUserVoiceRecorder(),
  });

  final NativeAudioPlaybackGateway _playback;
  final UserVoiceRecorder _recorder;
  AudioCatalog? _catalog;

  bool get canRecordVoice => _recorder.isAvailable;

  Future<AudioCatalog> loadCatalog() async {
    if (_catalog case final catalog?) return catalog;
    final raw = await rootBundle.loadString('assets/data/audio_manifest.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final schemaVersion = decoded['schemaVersion'] as int? ?? 0;
    if (schemaVersion != 1) {
      throw FormatException('Unsupported audio schema version: $schemaVersion');
    }

    final basePack = _parsePack(
      Map<String, dynamic>.from(decoded['basePack'] as Map),
    );
    if (!basePack.bundled) {
      throw const FormatException('The base audio pack must be bundled');
    }
    final downloadablePacks = [
      for (final item in decoded['downloadablePacks'] as List? ?? const [])
        _parsePack(Map<String, dynamic>.from(item as Map)),
    ];
    final speakers = [
      for (final item in decoded['speakers'] as List? ?? const [])
        _parseSpeaker(Map<String, dynamic>.from(item as Map)),
    ];
    final packIds = {
      basePack.id,
      for (final pack in downloadablePacks) pack.id,
    };
    final speakerIds = {for (final speaker in speakers) speaker.id};
    if (packIds.length != 1 + downloadablePacks.length) {
      throw const FormatException('Duplicate audio pack id');
    }
    if (speakerIds.length != speakers.length) {
      throw const FormatException('Duplicate audio speaker id');
    }

    final clips = <String, NativeAudioClip>{};
    for (final rawClip in decoded['clips'] as List? ?? const []) {
      final json = Map<String, dynamic>.from(rawClip as Map);
      final clip = NativeAudioClip(
        id: json['id'] as String,
        speakerId: json['speakerId'] as String,
        dialect: json['dialect'] as String,
        durationMs: json['durationMs'] as int,
        version: json['version'] as int,
        sha256: json['sha256'] as String,
        languageTag: json['languageTag'] as String? ?? 'ce',
        license: json['license'] as String,
        assetPath: json['assetPath'] as String?,
        remotePath: json['remotePath'] as String?,
        packId: json['packId'] as String? ?? 'base',
        speed: json['speed'] == 'slow' ? AudioSpeed.slow : AudioSpeed.normal,
      );
      ChechenAudioPolicy.ensureAllowed(clip);
      if (!packIds.contains(clip.packId)) {
        throw FormatException(
          'Audio clip ${clip.id} references unknown pack ${clip.packId}',
        );
      }
      if (!speakerIds.contains(clip.speakerId)) {
        throw FormatException(
          'Audio clip ${clip.id} references unknown speaker '
          '${clip.speakerId}',
        );
      }
      if (clips.containsKey(clip.id)) {
        throw FormatException('Duplicate audio clip id: ${clip.id}');
      }
      clips[clip.id] = clip;
    }
    _catalog = AudioCatalog(
      schemaVersion: schemaVersion,
      basePack: basePack,
      downloadablePacks: downloadablePacks,
      speakers: speakers,
      clips: Map.unmodifiable(clips),
    );
    return _catalog!;
  }

  Future<bool> hasVerifiedClip(String? audioId) async {
    if (audioId == null || audioId.isEmpty) return false;
    final catalog = await loadCatalog();
    return catalog.clips.containsKey(audioId);
  }

  Future<AudioActionResult> play(String? audioId) async {
    if (!await hasVerifiedClip(audioId) || !_playback.isAvailable) {
      return AudioActionResult.unavailable;
    }
    await _playback.play(_catalog!.clips[audioId]!);
    return AudioActionResult.played;
  }

  Future<String?> recordUserVoice({required String? referenceAudioId}) async {
    if (!await hasVerifiedClip(referenceAudioId) || !_recorder.isAvailable) {
      return null;
    }
    return _recorder.record();
  }

  AudioPack _parsePack(Map<String, dynamic> json) {
    final pack = AudioPack(
      id: json['id'] as String,
      version: json['version'] as int,
      bundled: json['bundled'] as bool,
      downloadUrl: json['downloadUrl'] as String?,
      sha256: json['sha256'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
    );
    if (pack.id.trim().isEmpty || pack.version <= 0) {
      throw const FormatException('Invalid audio pack metadata');
    }
    if (!pack.bundled &&
        (pack.downloadUrl?.isEmpty != false ||
            !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(pack.sha256 ?? '') ||
            (pack.sizeBytes ?? 0) <= 0)) {
      throw FormatException(
        'Downloadable audio pack ${pack.id} requires URL, SHA-256 and size',
      );
    }
    return pack;
  }

  AudioSpeaker _parseSpeaker(Map<String, dynamic> json) {
    final speaker = AudioSpeaker(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      dialect: json['dialect'] as String,
      consentRef: json['consentRef'] as String,
    );
    if (speaker.id.trim().isEmpty ||
        speaker.displayName.trim().isEmpty ||
        speaker.dialect.trim().isEmpty ||
        speaker.consentRef.trim().isEmpty) {
      throw const FormatException('Invalid audio speaker metadata');
    }
    return speaker;
  }
}
