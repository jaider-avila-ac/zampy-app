import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

// Equivalente a src/services/dispositivoService.js en React

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

Future<Map<String, String>> _authHeaders() async {
  try {
    final raw = await _storage.read(key: 'auth');
    if (raw == null) return {'Content-Type': 'application/json'};
    final token = (jsonDecode(raw) as Map<String, dynamic>)['token'] as String?;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  } catch (_) {
    return {'Content-Type': 'application/json'};
  }
}

class DispositivoService {
  DispositivoService._();

  // GET /api/v1/dispositivos
  static Future<List<dynamic>> getDispositivos() async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('$kApiBase/api/v1/dispositivos'), headers: headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 401) throw Exception('Sesión expirada');
    if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
    return jsonDecode(res.body) as List;
  }

  // DELETE /api/v1/dispositivos/:id
  static Future<void> revocar(String id) async {
    final headers = await _authHeaders();
    final res = await http
        .delete(Uri.parse('$kApiBase/api/v1/dispositivos/$id'), headers: headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 401) throw Exception('Sesión expirada');
    if (res.statusCode != 200 && res.statusCode != 204) {
      String msg = 'Error ${res.statusCode}';
      try { msg = (jsonDecode(res.body) as Map)['message'] as String? ?? msg; } catch (_) {}
      throw Exception(msg);
    }
  }

  // GET /api/v1/user/me  (incluye codigoInv)
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('Authorization')) return null;
      final res = await http
          .get(Uri.parse('$kApiBase/api/v1/user/me'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
