import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Base URL del backend.
/// Dispositivo físico en la red local → IP de la PC host.
/// Producción → URL de Render.
const kApiBase = 'http://192.168.1.2:8083';
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

  // ── GET /api/user/me — provider info ──────────────────────────────────────
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      final res = await http
          .get(Uri.parse('$kApiBase/api/user/me'),
              headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── PUT /api/user/profile — nombre, apellido, foto ────────────────────────
  static Future<Map<String, dynamic>> updateProfile({
    required String nombre,
    required String apellido,
    XFile? foto,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest(
        'PUT', Uri.parse('$kApiBase/api/user/profile'))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['nombre'] = nombre
      ..fields['apellido'] = apellido;

    if (foto != null) {
      final bytes = await foto.readAsBytes();
      request.files.add(
          http.MultipartFile.fromBytes('foto', bytes, filename: foto.name));
    }

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw data['message'] as String? ?? 'Error al guardar perfil';
    }

    // Actualizar datos en storage con los valores devueltos por el servidor
    final current = await getAuthData() ?? {};
    await _storage.write(
      key: 'auth_data',
      value: jsonEncode({
        ...current,
        'nombre':   data['nombre']   ?? nombre,
        'apellido': data['apellido'] ?? apellido,
        if (data['avatar'] != null) 'avatar': data['avatar'],
      }),
    );
    return data;
  }

  // ── PUT /api/user/me/password ──────────────────────────────────────────────
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    final res = await http
        .put(
          Uri.parse('$kApiBase/api/user/me/password'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'currentPassword': currentPassword,
            'newPassword': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw data['message'] as String? ?? 'Error al cambiar contraseña';
    }
  }
}
