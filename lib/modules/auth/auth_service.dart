import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Base URL del backend.
/// Dispositivo físico en la red local → IP de la PC host.
/// Producción → URL de Render.
const kApiBase = 'http://192.168.1.7:8083';
const kGoogleAuthUrl = '$kApiBase/oauth2/authorization/google';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class AuthService {
  AuthService._();

  // ── Login email/password ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await http
        .post(
          Uri.parse('$kApiBase/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 403 &&
        data['message'] == 'EMAIL_NOT_VERIFIED') {
      throw 'Debes verificar tu correo antes de iniciar sesión.';
    }
    if (res.statusCode != 200) {
      throw (data['message'] as String? ??
          'Correo o contraseña incorrectos.');
    }

    await _saveSession(data);
    return data;
  }

  // ── Register ───────────────────────────────────────────────────────────────
  static Future<void> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    final res = await http
        .post(
          Uri.parse('$kApiBase/api/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombre': nombre.trim(),
            'apellido': apellido.trim(),
            'email': email.trim(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200 && res.statusCode != 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw (data['message'] as String? ??
          'No se pudo completar el registro.');
    }
  }

  // ── Guardar sesión OAuth (Google) ──────────────────────────────────────────
  /// Recibe el Map construido desde los query params del callback de Google.
  static Future<void> saveOAuthSession(Map<String, dynamic> data) =>
      _saveSession(data);

  // ── Helpers internos ───────────────────────────────────────────────────────
  static Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await _storage.write(key: 'jwt_token', value: token);
      await _storage.write(key: 'auth_data', value: jsonEncode(data));
    }
  }

  static Future<String?> getToken() => _storage.read(key: 'jwt_token');

  static Future<bool> isLoggedIn() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> getAuthData() async {
    final raw = await _storage.read(key: 'auth_data');
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> logout() => _storage.deleteAll();
}
