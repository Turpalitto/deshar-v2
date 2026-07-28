import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nokhchiin/core/services/chechen_audio_service.dart';
import 'package:nokhchiin/domain/entities/audio_entities.dart';
import 'package:nokhchiin/domain/services/chechen_audio_policy.dart';

NativeAudioClip _clip({String languageTag = 'ce'}) => NativeAudioClip(
  id: 'clip',
  speakerId: 'speaker',
  dialect: 'literary',
  durationMs: 900,
  version: 1,
  sha256: List.filled(64, 'a').join(),
  languageTag: languageTag,
  license: 'CC-BY-4.0',
  assetPath: 'assets/audio/clip.m4a',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native Chechen recording is allowed', () {
    expect(ChechenAudioPolicy.isAllowed(_clip()), isTrue);
  });

  test('Russian locale cannot be used for Chechen audio', () {
    expect(ChechenAudioPolicy.isAllowed(_clip(languageTag: 'ru-RU')), isFalse);
    expect(
      () => ChechenAudioPolicy.ensureAllowed(_clip(languageTag: 'ru-RU')),
      throwsArgumentError,
    );
  });

  test('recording without a license is rejected', () {
    final clip = NativeAudioClip(
      id: 'clip',
      speakerId: 'speaker',
      dialect: 'literary',
      durationMs: 900,
      version: 1,
      sha256: List.filled(64, 'a').join(),
      languageTag: 'ce',
      license: '',
      assetPath: 'assets/audio/clip.m4a',
    );

    expect(ChechenAudioPolicy.isAllowed(clip), isFalse);
  });

  test('bundled manifest exposes a valid base pack', () async {
    final catalog = await ChechenAudioService().loadCatalog();

    expect(catalog.schemaVersion, 1);
    expect(catalog.basePack.id, 'base');
    expect(catalog.basePack.bundled, isTrue);
    expect(catalog.downloadablePacks, isEmpty);
    expect(catalog.clips, isEmpty);
  });

  test('application source contains no Flutter TTS integration', () {
    final source = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync().toLowerCase())
        .join('\n');

    expect(source, isNot(contains('flutter_tts')));
    expect(source, isNot(contains("setlanguage('ru-ru")));
    expect(source, isNot(contains('setlanguage("ru-ru')));
  });
}
