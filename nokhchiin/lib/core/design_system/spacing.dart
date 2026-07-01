/// iOS-style spacing grid: базовый шаг 4pt, основной ритм 8pt.
abstract final class IosSpacing {
  /// 4pt — микро-отступы, иконка↔текст.
  static const double unit = 4;

  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;

  /// Стандартные горизонтальные поля экрана (iPhone).
  static const double screenHorizontal = x5;

  /// Вертикальный ритм между секциями.
  static const double sectionGap = x6;

  /// Внутренний padding карточки.
  static const double cardPadding = x4;

  /// Минимальная touch-target зона (HIG ~44pt).
  static const double minTouchTarget = 44;
}
