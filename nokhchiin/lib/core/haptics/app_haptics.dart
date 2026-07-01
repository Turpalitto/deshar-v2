import 'package:flutter/services.dart';

/// Единая точка haptic feedback для всего приложения.
///
/// Использует только встроенный [HapticFeedback] из `flutter/services.dart`
/// (без сторонних пакетов).
///
/// **iOS:** Taptic Engine — различимые light / medium / heavy / selection.
///
/// **Android:** поведение зависит от производителя и версии ОС: часто это
/// короткая системная вибрация, интенсивности могут не различаться, на части
/// устройств эффект не ощущается. Вызовы безопасны и не блокируются —
/// [HapticFeedback] на Android просто no-op или generic vibrate.
///
/// **Web / desktop:** обычно no-op; вызовы оставляем для единообразия API.
abstract final class AppHaptics {
  AppHaptics._();

  /// Успех: правильный ответ, завершение шага.
  static Future<void> success() => HapticFeedback.mediumImpact();

  /// Ошибка: неверный ответ, блокирующее действие.
  static Future<void> error() => HapticFeedback.heavyImpact();

  /// Выбор: переключатель, чип, сегмент.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Лёгкое касание: тап по активному элементу, мелкое подтверждение.
  static Future<void> lightTap() => HapticFeedback.lightImpact();
}
