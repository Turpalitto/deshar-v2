import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/dictionary_search_repository.dart';
import '../services/notification_service.dart';
import 'dictionary_search_providers.dart';
import 'user_profile_provider.dart';
import 'word_of_the_day_provider.dart';

/// Время по умолчанию для уведомлений — не настраивается через UI пока,
/// но уже параметризовано на будущее.
const kWordOfDayNotificationTime = TimeOfDay(hour: 9, minute: 0);
const kStreakReminderNotificationTime = TimeOfDay(hour: 20, minute: 0);

/// Пересчитывает слово на завтра и перевыставляет одноразовое уведомление
/// «слово дня» — общая логика для обоих мест, откуда она вызывается:
/// `app.dart` (при каждом открытии/возврате в приложение, через `WidgetRef`)
/// и `UserProfileNotifier.setNotificationsEnabled` (сразу при включении
/// настройки, через доменный `Ref`) — у локальных уведомлений нет способа
/// подставлять новый текст в уже запланированное повторяющееся уведомление,
/// поэтому единственный способ не показывать вчерашнее слово — перевыставлять
/// его заново при каждом шансе.
Future<void> rescheduleWordOfDay(
  NotificationService notifSvc,
  DictionarySearchRepository repo,
) async {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final entry = await wordForDate(repo, tomorrow);
  if (entry == null) return;
  await notifSvc.scheduleDailyWordOfTheDay(
    time: kWordOfDayNotificationTime,
    chechen: entry.chechen,
    russian: entry.russian,
  );
}

/// Хук для `app.dart`: перевыставляет уведомление, только если пользователь
/// включил уведомления в настройках.
Future<void> refreshWordOfDayNotificationIfEnabled(WidgetRef ref) async {
  final profile = ref.read(userProfileProvider).valueOrNull;
  if (profile == null || !profile.notificationsEnabled) return;

  await rescheduleWordOfDay(
    ref.read(notificationServiceProvider),
    ref.read(dictionarySearchRepoProvider),
  );
}
