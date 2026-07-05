import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nokhchiin/l10n/app_localizations.dart';
import 'core/design_system/ios_design_system.dart';
import 'core/design_system/theme_integration.dart';
import 'core/providers/notification_provider.dart';
import 'core/router/app_router.dart';
import 'core/design/theme/nokhchiin_theme.dart';
import 'core/design/theme/theme_provider.dart';
import 'core/providers/providers.dart';
import 'domain/entities/enums.dart';

class NokhchiinApp extends ConsumerStatefulWidget {
  const NokhchiinApp({super.key});

  @override
  ConsumerState<NokhchiinApp> createState() => _NokhchiinAppState();
}

class _NokhchiinAppState extends ConsumerState<NokhchiinApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshWordOfDayNotificationIfEnabled(ref);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshWordOfDayNotificationIfEnabled(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final themeMode = ref.watch(themeBrightnessProvider);
    final mode = profile?.mode ?? AppMode.kids;
    final age = profile?.ageGroup ?? KidsAgeGroup.age6to9;

    return MaterialApp.router(
      title: 'Нохчийн',
      debugShowCheckedModeBanner: false,
      theme: NokhchiinTheme.light(mode: mode, age: age),
      darkTheme: NokhchiinTheme.dark(mode: mode, age: age),
      themeMode: themeMode,
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      // iOS design system (ThemeExtension) + Dynamic Type — не трогает экраны.
      builder: (context, child) {
        final theme = DesignSystemIntegration.enhanceWithContext(context, Theme.of(context));
        final ios = theme.extension<IosDesignSystem>();
        final content = child ?? const SizedBox.shrink();
        return Theme(
          data: theme,
          child: ios == null
              ? content
              : CupertinoTheme(data: ios.cupertinoTheme, child: content),
        );
      },
    );
  }
}
