import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Локальные уведомления: стрик-напоминание (повторяющееся, текст не
/// меняется) и «слово дня» (одноразовое — см. [scheduleDailyWordOfTheDay]
/// про то, почему у него нет режима "повторять вечно").
///
/// Ленивая инициализация по образцу AnalyticsService — ничего не
/// создаётся до первого реального использования.
class NotificationService {
  NotificationService();

  static const _streakChannelId = 'streak_reminder_channel';
  static const _streakChannelName = 'Напоминание о стрике';
  static const _wordChannelId = 'word_of_day_channel';
  static const _wordChannelName = 'Слово дня';

  static const _streakNotificationId = 1001;
  static const _wordNotificationId = 1002;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone));
    } catch (_) {
      // Не удалось определить таймзону устройства — оставляем UTC-фолбэк
      // timezone-пакета, чем падать целиком.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _streakChannelId,
      _streakChannelName,
      importance: Importance.defaultImportance,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _wordChannelId,
      _wordChannelName,
      importance: Importance.defaultImportance,
    ));

    _initialized = true;
  }

  /// Запрашивает системное разрешение на уведомления. `false` — отказано
  /// или платформа не поддерживается.
  Future<bool> requestPermission() async {
    await _ensureInitialized();

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<DarwinFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }

    return false;
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Повторяющееся ежедневное напоминание о стрике. Текст фиксирован и не
  /// меняется день ото дня, поэтому достаточно поставить его один раз при
  /// включении настройки — ОС сама повторяет его каждый день.
  Future<void> scheduleDailyStreakReminder({required TimeOfDay time}) async {
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      _streakNotificationId,
      'Не теряй стрик! 🔥',
      'Зайди в Нохчийн сегодня, чтобы продолжить серию дней подряд.',
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(_streakChannelId, _streakChannelName),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Одноразовое уведомление на ближайшее наступление [time] с текстом
  /// конкретного дня. Не использует matchDateTimeComponents (повтор навсегда
  /// с одним и тем же текстом), т.к. слово дня обязано меняться каждый
  /// день — вызывающая сторона обязана перевызывать этот метод при каждом
  /// открытии приложения, пересчитывая слово на следующее наступление
  /// времени (см. `notification_provider.dart`).
  Future<void> scheduleDailyWordOfTheDay({
    required TimeOfDay time,
    required String chechen,
    required String russian,
  }) async {
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      _wordNotificationId,
      'Слово дня: $chechen',
      russian,
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(_wordChannelId, _wordChannelName),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }
}

final notificationServiceProvider = Provider<NotificationService>((_) => NotificationService());
