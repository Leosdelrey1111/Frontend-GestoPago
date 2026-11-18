import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SessionStorage {
  static const _storage = FlutterSecureStorage();
  static const String _keyToken = 'jwt_token';
  static const String _keyDeviceId = 'device_id';
  static const String _keyUserEmail = 'user_email';

  /// Obtiene el Device ID persistente unico de esta instalacion/navegador
  /// Si no existe, se genera un UUID v4 y se almacena permanentemente.
  static Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_keyDeviceId);
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = const Uuid().v4();
        await prefs.setString(_keyDeviceId, deviceId);
      }
      return deviceId;
    } catch (_) {
      // Fallback
      return const Uuid().v4();
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _keyToken, value: token);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
    }
  }

  static Future<String?> getToken() async {
    try {
      String? token = await _storage.read(key: _keyToken);
      if (token != null) return token;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  static Future<void> clearSession() async {
    try {
      await _storage.delete(key: _keyToken);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserEmail);
  }
}

