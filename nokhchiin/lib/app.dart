import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/providers.dart';
import 'domain/entities/enums.dart';

class NokhchiinApp extends ConsumerWidget {
  const NokhchiinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    return MaterialApp.router(
      title: 'Нохчийн',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(
        mode: profile?.mode ?? AppMode.kids,
        age: profile?.ageGroup ?? KidsAgeGroup.age6to9,
      ),
      routerConfig: appRouter,
    );
  }
}
