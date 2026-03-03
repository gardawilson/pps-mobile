import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NetworkMode { auto, internal, public }

class NetworkModeConfig {
  static const String _prefsKey = 'network_mode';
  static NetworkMode _currentMode = NetworkMode.internal;
  static bool _initialized = false;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    _currentMode = _normalizeMode(_parseMode(saved) ?? _defaultModeFromEnv());
    await prefs.setString(_prefsKey, _currentMode.name);
    _initialized = true;
  }

  static NetworkMode get currentMode => _currentMode;

  static String get currentModeLabel {
    switch (_currentMode) {
      case NetworkMode.internal:
        return 'Internal';
      case NetworkMode.public:
        return 'Public';
      case NetworkMode.auto:
        return 'Internal';
    }
  }

  static Future<void> setMode(NetworkMode mode) async {
    _currentMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  static String get apiBaseUrl {
    _ensureInitialized();
    switch (_currentMode) {
      case NetworkMode.internal:
        return _internalApiUrl;
      case NetworkMode.public:
        return _publicApiUrl;
      case NetworkMode.auto:
        return _internalApiUrl;
    }
  }

  static String get updateBaseUrl {
    _ensureInitialized();
    switch (_currentMode) {
      case NetworkMode.internal:
        return _internalUpdateUrl;
      case NetworkMode.public:
        return _publicUpdateUrl;
      case NetworkMode.auto:
        return _internalUpdateUrl;
    }
  }

  static String get internalApiBaseUrl => _internalApiUrl;

  static String get publicApiBaseUrl => _publicApiUrl;

  static NetworkMode _defaultModeFromEnv() {
    final raw = (dotenv.env['DEFAULT_NETWORK_MODE'] ?? '').trim().toLowerCase();
    return _normalizeMode(_parseMode(raw) ?? NetworkMode.internal);
  }

  static NetworkMode? _parseMode(String? raw) {
    if (raw == null) return null;
    switch (raw.trim().toLowerCase()) {
      case 'internal':
        return NetworkMode.internal;
      case 'public':
        return NetworkMode.public;
      case 'auto':
        return NetworkMode.auto;
      default:
        return null;
    }
  }

  static NetworkMode _normalizeMode(NetworkMode mode) {
    if (mode == NetworkMode.auto) return NetworkMode.internal;
    return mode;
  }

  static String get _internalApiUrl =>
      (dotenv.env['API_BASE_URL_INTERNAL'] ?? dotenv.env['API_BASE_URL'] ?? '')
          .trim();

  static String get _publicApiUrl =>
      (dotenv.env['API_BASE_URL_PUBLIC'] ?? '').trim();

  static String get _internalUpdateUrl =>
      (dotenv.env['UPDATE_BASE_URL_INTERNAL'] ??
              dotenv.env['UPDATE_BASE_URL'] ??
              '')
          .trim();

  static String get _publicUpdateUrl =>
      (dotenv.env['UPDATE_BASE_URL_PUBLIC'] ?? '').trim();

  static void _ensureInitialized() {
    if (_initialized) return;
    _currentMode = _normalizeMode(_defaultModeFromEnv());
    _initialized = true;
  }
}
