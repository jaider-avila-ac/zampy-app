import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_client.dart';

// Equivalente a authService.updateProfile/changePassword/getAccountDeleteCode/deleteAccount
// y a los PUT de ubicación y contacto de useProfile.js en React.

Map<String, dynamic> _asMap(dynamic data) =>
    data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

class ProfileService {
  ProfileService._();

  // PUT /api/v1/user/profile  (multipart/form-data)
  // Devuelve el usuario actualizado { nombre, apellido, avatar, ... }
  static Future<Map<String, dynamic>> updateProfile({
    required String nombre,
    required String apellido,
    File? fotoFile,
  }) async {
    Future<http.StreamedResponse> send() async {
      final token = ApiClient.instance.tokenProvider?.call();
      if (token == null || token.isEmpty) throw Exception('Sesión no válida');
      final req =
          http.MultipartRequest(
              'PUT',
              Uri.parse('$kApiBase/api/v1/user/profile'),
            )
            ..headers['Authorization'] = 'Bearer $token'
            ..fields['nombre'] = nombre
            ..fields['apellido'] = apellido;
      if (fotoFile != null) {
        req.files.add(await http.MultipartFile.fromPath('foto', fotoFile.path));
      }
      return req.send().timeout(const Duration(seconds: 30));
    }

    var streamed = await send();
    if (streamed.statusCode == 401 &&
        (await ApiClient.instance.refreshHandler?.call() ?? false)) {
      streamed = await send();
    }
    final body = await streamed.stream.bytesToString();
    Map<String, dynamic> data = {};
    try {
      data = _asMap(jsonDecode(body));
    } catch (_) {}

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception(data['message'] as String? ?? 'Error al guardar perfil');
    }
    return data;
  }

  // PUT /api/v1/user/me/password — 401 con mensaje = contraseña actual incorrecta
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.instance.put(
      '/api/v1/user/me/password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  // GET /api/v1/user/me — provider, ubicacion, contacto, codigoInv
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      return _asMap(await ApiClient.instance.get('/api/v1/user/me'));
    } catch (_) {
      return null;
    }
  }

  // PUT /api/v1/user/me/location → { ok, ubicacion }
  static Future<Map<String, dynamic>?> saveLocation(
    String municipioCodigo,
  ) async {
    final data = _asMap(
      await ApiClient.instance.put(
        '/api/v1/user/me/location',
        body: {'municipioCodigo': municipioCodigo},
      ),
    );
    final u = data['ubicacion'];
    return u is Map ? Map<String, dynamic>.from(u) : null;
  }

  // PUT /api/v1/user/me/contacto → teléfono normalizado a E.164
  static Future<Map<String, dynamic>> saveContacto({
    required String telefono,
    required String direccion,
    required String direccionReferencia,
  }) async {
    return _asMap(
      await ApiClient.instance.put(
        '/api/v1/user/me/contacto',
        body: {
          'telefono': telefono,
          'direccion': direccion,
          'direccionReferencia': direccionReferencia,
        },
      ),
    );
  }

  // GET /api/v1/user/me/delete-code — código de 5 caracteres, vence en 5 min
  static Future<String> getAccountDeleteCode() async {
    final data = _asMap(
      await ApiClient.instance.get('/api/v1/user/me/delete-code'),
    );
    final code = data['code']?.toString();
    if (code == null || code.isEmpty) {
      throw Exception('No se pudo generar el código de confirmación.');
    }
    return code;
  }

  // DELETE /api/v1/user/me — irreversible: menús propios, actividad y datos personales
  static Future<void> deleteAccount(String code) async {
    await ApiClient.instance.delete(
      '/api/v1/user/me',
      headers: {'X-Delete-Code': code},
    );
  }
}
