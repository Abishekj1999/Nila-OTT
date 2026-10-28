import 'package:flutter/foundation.dart';

/// Environment configuration, supplied at build time with `--dart-define`.
///
///   flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
///
/// Without a value, debug builds talk to the local Laravel server
/// (`php artisan serve` on port 8000). Release builds must pass one.
class AppConfig {
  const AppConfig({required this.apiBaseUrl, this.devMediaOrigin});

  final String apiBaseUrl;

  /// Debug-only fix for media URLs the backend builds from a mis-set
  /// `APP_URL` (e.g. `http://localhost/storage/...` without the port, which
  /// also points at the device itself on an Android emulator). When set,
  /// any media URL on `localhost`/`127.0.0.1` is rewritten to this origin.
  final Uri? devMediaOrigin;

  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  factory AppConfig.fromEnvironment() {
    final base = _definedBaseUrl.isNotEmpty ? _definedBaseUrl : _localBaseUrl();
    final origin = Uri.parse(base).replace(path: '', query: null);
    return AppConfig(
      apiBaseUrl: base.endsWith('/') ? base.substring(0, base.length - 1) : base,
      devMediaOrigin: kReleaseMode ? null : origin,
    );
  }

  static String _localBaseUrl() {
    // The Android emulator reaches the host machine through 10.0.2.2.
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return isAndroid ? 'http://10.0.2.2:8000/api/v1' : 'http://127.0.0.1:8000/api/v1';
  }

  /// Returns a usable media URL, or null for empty values.
  String? mediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final origin = devMediaOrigin;
    if (origin == null) return url;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      return uri
          .replace(scheme: origin.scheme, host: origin.host, port: origin.port)
          .toString();
    }
    return url;
  }
}
