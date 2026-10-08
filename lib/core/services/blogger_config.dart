/// Auth modes for the Blogger API.
enum BloggerAuthMode {
  /// Public Atom feed — no credentials required.
  unauthenticated,

  /// Google Blogger API v3 — requires a Firebase ID token.
  authenticated,
}

/// Compile-time and runtime configuration for the Blogger data source.
class BloggerConfig {
  BloggerConfig._();

  /// The Blogger blog ID supplied at build time via `--dart-define`.
  static const String blogId = String.fromEnvironment(
    'BLOGGER_BLOG_ID',
    defaultValue: '1774904866501098696',
  );

  /// Returns the current auth mode.
  ///
  /// TODO: Replace with a real Firebase Auth check once Firebase is wired up.
  static BloggerAuthMode get currentAuthMode => BloggerAuthMode.unauthenticated;

  /// Base URL for the Atom / JSON feed API (unauthenticated).
  static const String feedBaseUrl = 'https://www.blogger.com/feeds';

  /// Base URL for the Blogger REST API v3 (authenticated).
  static const String v3BaseUrl = 'https://www.googleapis.com/blogger/v3';
}
