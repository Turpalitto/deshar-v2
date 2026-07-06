/// Разделяет число пробелами по тысячам: 134346 -> "134 346".
String formatThousands(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Правильная форма русского счётного существительного для числа [n]:
/// 1 слово / 2 слова / 5 слов. Раньше "слов" использовалось для любого
/// числа, включая "1 слов" (аудит §7).
String pluralize(int n, {required String one, required String few, required String many}) {
  final mod100 = n.abs() % 100;
  if (mod100 >= 11 && mod100 <= 14) return many;
  switch (n.abs() % 10) {
    case 1:
      return one;
    case 2:
    case 3:
    case 4:
      return few;
    default:
      return many;
  }
}

/// Частный случай для "слово/слова/слов" — используется чаще всего.
String wordsCount(int n) => '$n ${pluralize(n, one: 'слово', few: 'слова', many: 'слов')}';
