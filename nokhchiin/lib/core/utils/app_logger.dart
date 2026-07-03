import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract final class AppLogger {
  static bool _sentryEnabled = false;

  static void configure({required bool sentryEnabled}) {
    _sentryEnabled = sentryEnabled;
  }

  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[WARN] $message${error != null ? ' | $error' : ''}');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
    if (_sentryEnabled) {
      Sentry.captureMessage(
        error != null ? '$message | $error' : message,
        level: SentryLevel.warning,
      );
    }
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message${error != null ? ' | $error' : ''}');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
    if (_sentryEnabled) {
      Sentry.captureException(
        error ?? Exception(message),
        stackTrace: stackTrace,
      );
    }
  }
}
