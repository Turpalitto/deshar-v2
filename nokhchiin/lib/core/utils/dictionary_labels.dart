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

  static String? categoryLabel(String? category, {List<String> sources = const []}) {
    if (category != null && category.isNotEmpty) {
      final mapped = _labels[category];
      if (mapped != null) return mapped;
      if (category != 'default') return category;
    }
    if (sources.contains('verified') || sources.contains('lessons')) {
      return 'Проверено';
    }
    return sources.contains('maciev') || sources.isEmpty ? 'Мациев' : null;
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
