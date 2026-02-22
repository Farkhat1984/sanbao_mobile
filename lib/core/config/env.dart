/// Environment configuration resolved from --dart-define flags.
///
/// Usage at build time:
/// ```
/// flutter run --dart-define=API_BASE_URL=https://api.sanbao.ai
/// flutter run --dart-define=SENTRY_DSN=https://xxx@sentry.io/yyy
/// flutter run --dart-define=GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
/// flutter run --dart-define=ENV=production
/// ```
library;

/// Provides typed access to compile-time environment variables.
abstract final class Env {
  /// The base URL of the Sanbao API server.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Sentry DSN for error tracking. Empty disables Sentry.
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
  );

  /// Google OAuth client ID for sign-in.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );

  /// Current environment: development, staging, production.
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  /// Whether the app is running in production mode.
  static bool get isProduction => environment == 'production';

  /// Whether the app is running in staging mode.
  static bool get isStaging => environment == 'staging';

  /// Whether the app is running in development mode.
  static bool get isDevelopment => environment == 'development';

  /// Whether Sentry error tracking is enabled.
  static bool get isSentryEnabled => sentryDsn.isNotEmpty;

  /// Whether Google Sign-In is configured.
  static bool get isGoogleSignInEnabled => googleClientId.isNotEmpty;

  /// Whether to enable debug logging.
  static const bool enableDebugLogging = bool.fromEnvironment(
    'DEBUG_LOGGING',
  );
}
