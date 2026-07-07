import 'dart:ui';

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
      _installErrorHandlers();
      await initApp();
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

  static void _installErrorHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      AppLogger.error('Uncaught platform error', error: error, stackTrace: stackTrace);
      return true;
    };
  }

  static Future<void> capture(
    Object error, {
    StackTrace? stackTrace,
    String? hint,
  }) async {
    if (!isEnabled) return;
    Hint? hintObj;
    if (hint != null) {
      hintObj = Hint();
      hintObj.set('hint', hint);
    }
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: hintObj,
    );
  }
}
