import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

// Equivalente a authService.updateProfile() y authService.changePassword() en React

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

Future<String?> _getToken() async {
  try {
    final raw = await _storage.read(key: 'auth');
    if (raw == null) return null;
    return (jsonDecode(raw) as Map<String, dynamic>)['token'] as String?;
  } catch (_) {
    return null;
  }
}

class ProfileService {
  ProfileService._();

  // PUT /api/v1/user/profile  (multipart/form-data)
  // Devuelve el usuario actualizado { nombre, apellido, avatar, ... }
  static Future<Map<String, dynamic>> updateProfile({
    required String nombre,
    required String apellido,
    File? fotoFile,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Sesión no válida');

    final req = http.MultipartRequest(
      'PUT',
      Uri.parse('$kApiBase/api/v1/user/profile'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['nombre']   = nombre
      ..fields['apellido'] = apellido;

    if (fotoFile != null) {
      req.files.add(await http.MultipartFile.fromPath('foto', fotoFile.path));
    }

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final body     = await streamed.stream.bytesToString();
    final data     = jsonDecode(body) as Map<String, dynamic>;

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception(data['message'] as String? ?? 'Error al guardar perfil');
    }
    return data;
  }

  // PUT /api/v1/user/me/password
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Sesión no válida');

    final res = await http.put(
      Uri.parse('$kApiBase/api/v1/user/me/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 401) {
      throw Exception(data['message'] as String? ?? 'Sesión expirada');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['message'] as String? ?? 'Error al cambiar la contraseña');
    }
  }

  // GET /api/v1/user/me  → devuelve provider (LOCAL | GOOGLE)
  static Future<String?> getProvider() async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$kApiBase/api/v1/user/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return (jsonDecode(res.body) as Map<String, dynamic>)['provider'] as String?;
    } catch (_) {
      return null;
    }
  }
}
