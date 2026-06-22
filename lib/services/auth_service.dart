import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

// Equivalente a src/services/authService.js en React

class AuthServiceException implements Exception {
  final String message;
  final int?   status;
  final String? code;
  const AuthServiceException(this.message, {this.status, this.code});
  @override String toString() => message;
}

class AuthService {
  AuthService._();

  // POST /api/v1/auth/login
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final res = await http.post(
      Uri.parse('$kApiBase/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    ).timeout(const Duration(seconds: 15));
    final data = _decodeBody(res.body);
    if (!res.ok) {
      throw AuthServiceException(
        data['message'] as String? ?? 'Correo o contraseña incorrectos.',
        status: res.statusCode,
      );
    }
    return data;
  }

  // POST /api/v1/auth/pre-register
  static Future<void> preRegister({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    String? invRef,
  }) async {
    final body = <String, dynamic>{
      'nombre': nombre, 'apellido': apellido,
      'email': email.trim(), 'password': password,
    };
    if (invRef != null) body['invRef'] = invRef;
    final res = await http.post(
      Uri.parse('$kApiBase/api/v1/auth/pre-register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
    if (!res.ok) {
      final data = _decodeBody(res.body);
      throw AuthServiceException(data['message'] as String? ?? 'No se pudo completar el registro.');
    }
  }

  // POST /api/v1/auth/register  (verifica código y activa cuenta)
  static Future<Map<String, dynamic>> verifyAndRegister(String email, String code) async {
    final res = await http.post(
      Uri.parse('$kApiBase/api/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'code': code.trim()}),
    ).timeout(const Duration(seconds: 15));
    final data = _decodeBody(res.body);
    if (!res.ok) {
      throw AuthServiceException(
        data['message'] as String? ?? 'Código incorrecto.',
        status: res.statusCode,
      );
    }
    return data;
  }

  // POST /api/v1/auth/forgot-password
  static Future<void> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$kApiBase/api/v1/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    ).timeout(const Duration(seconds: 15));
    if (!res.ok) {
      final data = _decodeBody(res.body);
      throw AuthServiceException(
        data['message'] as String? ?? 'Error de conexión.',
        code: data['message'] as String?,
      );
    }
  }

  // POST /api/v1/auth/resend-verification
  static Future<void> resendVerification(String email) async {
    final res = await http.post(
      Uri.parse('$kApiBase/api/v1/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    ).timeout(const Duration(seconds: 15));
    if (!res.ok) {
      final data = _decodeBody(res.body);
      throw AuthServiceException(
        data['message'] as String? ?? 'No se pudo reenviar el código.',
        status: res.statusCode,
      );
    }
  }

  // POST /api/v1/auth/reset-password
  static Future<void> resetPassword(String token, String password) async {
    final res = await http.post(
      Uri.parse('$kApiBase/api/v1/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'password': password}),
    ).timeout(const Duration(seconds: 15));
    if (!res.ok) {
      final data = _decodeBody(res.body);
      throw AuthServiceException(data['message'] as String? ?? 'No se pudo cambiar la contraseña.');
    }
  }

  // POST /api/v1/auth/google/token  (mobile native)
  static Future<Map<String, dynamic>> loginWithGoogleToken(String idToken) async {
    final res = await http.post(
      Uri.parse('$kApiBase/api/v1/auth/google/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    ).timeout(const Duration(seconds: 15));
    final data = _decodeBody(res.body);
    if (!res.ok) {
      throw AuthServiceException(
        data['message'] as String? ?? 'Error con Google.',
        status: res.statusCode,
      );
    }
    return data;
  }

  static Map<String, dynamic> _decodeBody(String body) {
    try { return jsonDecode(body) as Map<String, dynamic>; } catch (_) { return {}; }
  }
}

extension on http.Response {
  bool get ok => statusCode >= 200 && statusCode < 300;
}
