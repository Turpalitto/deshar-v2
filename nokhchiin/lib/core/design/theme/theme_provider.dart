import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/providers.dart';
import 'nokhchiin_theme.dart';

/// Светлая/тёмная схема (системная или ручная).
final themeBrightnessProvider = StateProvider<ThemeMode>(
  (_) => ThemeMode.system,
);

/// Активная тема с учётом режима пользователя (kids/adult).
final activeThemeProvider = Provider<ThemeData>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final mode = profile?.mode ?? AppMode.kids;
  final age = profile?.ageGroup ?? KidsAgeGroup.age6to9;
  return NokhchiinTheme.light(mode: mode, age: age);
});

final activeDarkThemeProvider = Provider<ThemeData>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final mode = profile?.mode ?? AppMode.kids;
  final age = profile?.ageGroup ?? KidsAgeGroup.age6to9;
  return NokhchiinTheme.dark(mode: mode, age: age);
});
