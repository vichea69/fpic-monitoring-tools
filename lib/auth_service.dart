import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'service/auth_service.dart' as api;

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  static const _kLoggedInKey = 'loggedIn_v1';
  static bool _isLoggedIn = false;
  static SharedPreferences? _prefs;
  static final api.AuthService _apiAuthService = api.AuthService();

  /// Initialize persisted auth state. Call before runApp.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final hasToken = await _apiAuthService.getToken();
    final persistedLogin = _prefs?.getBool(_kLoggedInKey) ?? false;
    _isLoggedIn = persistedLogin && hasToken != null && hasToken.isNotEmpty;

    if (!_isLoggedIn) {
      try {
        await _prefs?.remove(_kLoggedInKey);
      } catch (_) {}
    }
  }

  static bool get isLoggedIn => _isLoggedIn;

  /// Simple credential-based login helper.
  /// Authenticates against backend API and returns the username.
  static Future<String> loginWithCredentials(
    String username,
    String password,
  ) async {
    if (username.isEmpty || password.isEmpty) {
      throw AuthException('Please provide username and password');
    }

    final result = await _apiAuthService.login(
      identifier: username,
      password: password,
    );

    if (result['success'] == true) {
      _isLoggedIn = true;
      try {
        await _prefs?.setBool(_kLoggedInKey, true);
      } catch (_) {}
      return username;
    }

    final message = _extractApiMessage(result['message']);
    throw AuthException(message);
  }

  /// Local static credentials are removed. Keep this for compatibility only.
  static Future<void> addCredential(String username, String password) async {
    throw AuthException('This app now uses API authentication only.');
  }

  /// Local static credentials are removed. Keep this for compatibility only.
  static Future<void> removeCredential(String username) async {
    throw AuthException('This app now uses API authentication only.');
  }

  /// Returns an empty list because local static users are no longer used.
  static List<String> get registeredUsernames => const [];

  /// Clears persisted login state.
  static Future<void> logout() async {
    _isLoggedIn = false;
    try {
      await _apiAuthService.logout();
      await _prefs?.remove(_kLoggedInKey);
    } catch (_) {}
  }

  static String _extractApiMessage(dynamic message) {
    if (message is String && message.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(message);
        if (decoded is Map<String, dynamic>) {
          final nested = decoded['error'];
          if (nested is Map<String, dynamic>) {
            final nestedMessage = nested['message']?.toString();
            if (nestedMessage != null && nestedMessage.trim().isNotEmpty) {
              return nestedMessage;
            }
          }
        }
      } catch (_) {
        return message;
      }
      return message;
    }

    if (message is Map<String, dynamic>) {
      final nested = message['error'];
      if (nested is Map<String, dynamic>) {
        final nestedMessage = nested['message']?.toString();
        if (nestedMessage != null && nestedMessage.trim().isNotEmpty) {
          return nestedMessage;
        }
      }
      final directMessage = message['message']?.toString();
      if (directMessage != null && directMessage.trim().isNotEmpty) {
        return directMessage;
      }
    }

    return 'Invalid username or password';
  }
}
