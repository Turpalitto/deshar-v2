// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory.current.path.endsWith('tools')
      ? Directory.current.parent
      : Directory.current;
  final lessonsFile = File('${root.path}/nokhchiin/assets/data/lessons.json');
  final correctionsFile = File('${root.path}/vocabulary_corrections.json');
  final outAssets = File('${root.path}/nokhchiin/assets/data/curated_vocabulary.json');
  final outRoot = File('${root.path}/curated_vocabulary.json');

  final byKey = <String, Map<String, dynamic>>{};

  void add(
    String ce,
    String ru,
    String category,
    List<String> sources, {
    String? hint,
    String? emoji,
    String? pronunciation,
  }) {
    final key = ce.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (byKey.containsKey(key)) return;
    final entry = <String, dynamic>{
      'chechen': ce.isEmpty ? ce : ce[0].toUpperCase() + ce.substring(1),
      'russian': ru,
      'category': category,
      'emoji': emoji ?? _emoji(category),
      'hint': hint ?? 'Учебное слово: $ru',
      'sources': sources,
    };
    if (pronunciation != null && pronunciation.isNotEmpty) {
      entry['pronunciation'] = pronunciation;
    }
    byKey[key] = entry;
  }

  final lessons = jsonDecode(lessonsFile.readAsStringSync(encoding: utf8)) as List;
  for (final lesson in lessons) {
    final cat = lesson['id'] as String;
    for (final w in lesson['words'] as List) {
      final map = w as Map<String, dynamic>;
      add(
        map['chechen'] as String,
        map['russian'] as String,
        cat,
        ['lessons', 'curated'],
        hint: map['hint'] as String?,
        emoji: map['emoji'] as String?,
        pronunciation: map['pronunciation'] as String?,
      );
    }
  }

  if (correctionsFile.existsSync()) {
    final corr = jsonDecode(correctionsFile.readAsStringSync(encoding: utf8))
        as Map<String, dynamic>;
    final overrides = corr['overrides'] as Map<String, dynamic>? ?? {};
    for (final item in overrides.values) {
      final map = item as Map<String, dynamic>;
      add(
        map['chechen'] as String,
        map['russian'] as String,
        (map['category'] as String?) ?? 'default',
        <String>{
          ...((map['sources'] as List?)?.cast<String>() ?? []),
          'curated',
          'verified',
        }.toList(),
        hint: map['hint'] as String?,
        emoji: map['emoji'] as String?,
      );
    }
  }

  final entries = byKey.values.toList()
    ..sort((a, b) => (a['chechen'] as String).toLowerCase().compareTo(
          (b['chechen'] as String).toLowerCase(),
        ));

  final payload = {
    'sources': [
      {'id': 'maciev', 'title': 'Мациев А.Г. Чеченско-русский словарь'},
      {'id': 'curated', 'title': 'Проверенная учебная лексика'},
    ],
    'totalEntries': entries.length,
    'entries': entries,
  };

  final json = const JsonEncoder.withIndent('  ').convert(payload);
  outAssets.writeAsStringSync(json, encoding: utf8);
  outRoot.writeAsStringSync(json, encoding: utf8);
  print('curated: ${entries.length} entries');
}

String _emoji(String category) => switch (category) {
      'greetings' => '👋',
      'animals' => '🐾',
      'colors' => '🎨',
      'numbers' => '🔢',
      'family' => '❤️',
      'food' => '🍎',
      'nature' => '🌳',
      'body' => '🫀',
      'home' => '🏠',
      'verbs' => '⚡',
      'adjectives' => '✨',
      'phrases' => '💬',
      'dialogues' => '🗣️',
      _ => '📖',
    };