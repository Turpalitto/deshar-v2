import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../utils/app_logger.dart';

/// DSN передаётся при сборке: --dart-define=SENTRY_DSN=https://...
const kSentryDsn = String.fromEnvironment('SENTRY_DSN');

abstract final class CrashReporter {
  static bool get isEnabled => kSentryDsn.isNotEmpty;

  static Future<void> bootstrap(Future<void> Function() initApp) async {
    if (!isEnabled) {
      AppLogger.configure(sentryEnabled: false);
      await _runWithZoneGuards(initApp);
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = kSentryDsn;
        options.tracesSampleRate = 0;
        options.sendDefaultPii = false;
        options.environment = kReleaseMode ? 'production' : 'development';
      },
      appRunner: () async {
        AppLogger.configure(sentryEnabled: true);
        await initApp();
      },
    );
  }

  static Future<void> _runWithZoneGuards(Future<void> Function() initApp) async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    await runZonedGuarded(() async {
      await initApp();
    }, (error, stackTrace) {
      AppLogger.error('Uncaught zone error', error: error, stackTrace: stackTrace);
    });
  }

  static Future<void> capture(
    Object error, {
    StackTrace? stackTrace,
    String? hint,
  }) async {
    if (!isEnabled) return;
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: hint != null ? Hint() : null,
    );
  }
}
