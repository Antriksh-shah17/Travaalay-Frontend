import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _defaultBackendUrl =
      'https://wnn3xmpd-5000.inc1.devtunnels.ms';
  static const String _envBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: _defaultBackendUrl,
  );

  static final String rootUrl = _resolveBackendUrl();

  static final String apiBaseUrl = '$rootUrl/api';
  static final String authBaseUrl = '$apiBaseUrl/auth';
  static final String usersBaseUrl = '$apiBaseUrl/users';
  static final String translatorsBaseUrl = '$apiBaseUrl/translators';
  static final String packagesBaseUrl = '$apiBaseUrl/packages';
  static final String blogsBaseUrl = '$apiBaseUrl/blogs';
  static final String eventsBaseUrl = '$apiBaseUrl/events';
  static final String travaiBaseUrl = '$apiBaseUrl/travai';

  static String _resolveBackendUrl() {
    final envUrl = _normalizeBaseUrl(_envBackendUrl);
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    if (kIsWeb) return _defaultBackendUrl;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return _defaultBackendUrl;
    }
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return _defaultBackendUrl;
    }

    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
