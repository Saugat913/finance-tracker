import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Lightweight telemetry and crash-reporting service backed by Sentry.
///
/// Captures breadcrumbs, handled/unhandled exceptions, and domain events
/// (e.g. shift clock-ins, backup exports, goal completions) so production
/// issues can be diagnosed without collecting sensitive personal data.
class TelemetryService {
  TelemetryService._();

  static final TelemetryService instance = TelemetryService._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Initializes Sentry and telemetry tracking.
  /// Pass [dsn] via environment (`--dart-define=SENTRY_DSN=...`) or directly.
  static Future<void> init({
    String? dsn,
    required Future<void> Function() runAppCallback,
  }) async {
    final effectiveDsn = dsn ??
        const String.fromEnvironment('SENTRY_DSN', defaultValue: '');

    if (effectiveDsn.isEmpty) {
      if (kDebugMode) {
        debugPrint('[Telemetry] SENTRY_DSN not provided; running without Sentry.');
      }
      _initialized = false;
      await runAppCallback();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = effectiveDsn;
        options.tracesSampleRate = 0.2;
        options.enableAutoSessionTracking = true;
        options.attachScreenshot = false; // privacy-first
        options.sendDefaultPii = false; // no personal data
        options.environment = kReleaseMode ? 'production' : 'development';
      },
      appRunner: runAppCallback,
    );
    _initialized = true;
  }

  /// Adds a diagnostic breadcrumb for user or system flow tracking.
  void log(String message, {String category = 'app', Map<String, dynamic>? data}) {
    if (kDebugMode) {
      debugPrint('[Telemetry][$category] $message ${data ?? ""}');
    }
    if (_initialized) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          data: data,
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }
  }

  /// Logs a business event (e.g. 'shift_started', 'transaction_added').
  void trackEvent(String name, [Map<String, dynamic>? parameters]) {
    log(name, category: 'event', data: parameters);
  }

  /// Captures an error with optional stack trace and metadata.
  Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? reason,
    Map<String, dynamic>? extra,
  }) async {
    if (kDebugMode) {
      debugPrint('[Telemetry] Exception: $exception ($reason)');
      if (stackTrace != null) debugPrint('$stackTrace');
    }
    if (_initialized) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (reason != null) scope.setTag('reason', reason);
          if (extra != null) {
            scope.setContexts('extra', extra);
          }
        },
      );
    }
  }
}
