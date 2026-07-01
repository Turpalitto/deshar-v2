import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/repositories.dart';

/// Озвучка: сначала запись носителя (assets), иначе TTS с профилем голоса.
class AudioService implements AudioRepository {
  AudioService() {
    _tts = FlutterTts();
    _player = AudioPlayer();
    _init();
  }

  late final FlutterTts _tts;
  late final AudioPlayer _player;
  Map<String, dynamic>? _manifest;

  Future<void> _init() async {
    await _tts.setSharedInstance(true);
    await _tts.awaitSpeakCompletion(true);
    try {
      final raw = await rootBundle.loadString('assets/data/audio_manifest.json');
      _manifest = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {}
  }

  String? _audioPath(String word, {required bool chechen}) {
    final entries = _manifest?['entries'] as Map<String, dynamic>?;
    if (entries == null) return null;
    final key = word.toLowerCase().replaceAll(' ', '');
    for (final e in entries.entries) {
      if (e.key.toLowerCase().replaceAll(' ', '') == key) {
        final map = e.value as Map<String, dynamic>;
        return chechen ? map['ce'] as String? : map['ru'] as String?;
      }
    }
    return null;
  }

  Future<bool> _playAsset(String path) async {
    try {
      await _player.play(AssetSource(path.replaceFirst('assets/', '')));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> speakChechen(String text,
      {VoiceProfile profile = VoiceProfile.childNormal}) async {
    final path = _audioPath(text, chechen: true);
    if (path != null && await _playAsset(path)) return;
    await _applyProfile(profile, slow: profile == VoiceProfile.childSlow ||
        profile == VoiceProfile.adultSlow);
    await _tts.setLanguage('ru-RU');
    await _tts.speak(text);
  }

  @override
  Future<void> speakRussian(String text,
      {VoiceProfile profile = VoiceProfile.adultNormal}) async {
    final path = _audioPath(text, chechen: false);
    if (path != null && await _playAsset(path)) return;
    await _applyProfile(profile, slow: profile == VoiceProfile.childSlow ||
        profile == VoiceProfile.adultSlow);
    await _tts.setLanguage('ru-RU');
    await _tts.speak(text);
  }

  Future<void> _applyProfile(VoiceProfile profile, {required bool slow}) async {
    final pitch = profile == VoiceProfile.childNormal ||
            profile == VoiceProfile.childSlow
        ? 1.15
        : 1.0;
    await _tts.setPitch(pitch);
    await _tts.setSpeechRate(slow ? 0.35 : 0.48);
  }
}
