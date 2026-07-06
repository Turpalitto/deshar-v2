/// Человекочитаемые подписи категорий словаря.
abstract final class DictionaryLabels {
  static const _labels = <String, String>{
    'greetings': 'Приветствия',
    'animals': 'Животные',
    'colors': 'Цвета',
    'numbers': 'Числа',
    'family': 'Семья',
    'food': 'Еда',
    'nature': 'Природа',
    'body': 'Тело',
    'home': 'Дом',
    'verbs': 'Глаголы',
  };

  /// Человекочитаемые названия источников — по манифесту `sources` в самом
  /// dictionary.json (`assets/data/dictionary.json` → `sources[].title`).
  /// Раньше здесь была метка только для `maciev` — 9 остальных источников
  /// (~32% словаря, ~43k записей из other/bersanov/gatitos/computer/
  /// num2words/daymohk/radio/literature/baltoslav) не получали никакой
  /// подписи происхождения (аудит §7).
  static const _sourceLabels = <String, String>{
    'maciev': 'Мациев',
    'aliroev': 'Алироев',
    'bersanov': 'Берсанов',
    'computer': 'Компьютерная лексика',
    'num2words': 'Числительные',
    'baltoslav': 'Baltoslav.eu',
    'daymohk': 'Даймохк',
    'gatitos': 'Gatitos',
    'radio': 'Radio Marsho',
    'literature': 'Художественная литература',
    'other': 'Общий словарь',
    'curated': 'Проверено',
  };

  static String? categoryLabel(String? category, {List<String> sources = const []}) {
    if (category != null && category.isNotEmpty) {
      final mapped = _labels[category];
      if (mapped != null) return mapped;
      if (category != 'default') return category;
    }
    if (sources.contains('verified') || sources.contains('lessons')) {
      return 'Проверено';
    }
    for (final s in sources) {
      final label = _sourceLabels[s];
      if (label != null) return label;
    }
    return sources.isEmpty ? 'Мациев' : null;
  }

  static String? displayTranscription(String chechen, String? pronunciation) {
    final p = pronunciation?.trim();
    if (p == null || p.isEmpty) return null;
    final ceNorm = chechen.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final pNorm = p.replaceAll('·', '').replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (pNorm == ceNorm) return null;
    if (p.toLowerCase() == chechen.toLowerCase()) return null;
    return p;
  }
}
