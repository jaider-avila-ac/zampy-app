import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

// Equivalente a src/services/invitacionService.js

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

Future<Map<String, String>> _authHeaders() async {
  try {
    final raw   = await _storage.read(key: 'auth');
    final token = raw != null
        ? (jsonDecode(raw) as Map<String, dynamic>)['token'] as String?
        : null;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  } catch (_) {
    return {'Content-Type': 'application/json'};
  }
}

class InvitacionService {
  InvitacionService._();

  // GET /api/v1/invitaciones/estado
  static Future<Map<String, dynamic>> getEstado() async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('$kApiBase/api/v1/invitaciones/estado'), headers: headers)
        .timeout(const Duration(seconds: 15));
    if (!res.ok) throw Exception('Error al cargar estado de invitaciones');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // PUT /api/v1/invitaciones/toggle
  static Future<Map<String, dynamic>> toggleActivo() async {
    final headers = await _authHeaders();
    final res = await http
        .put(Uri.parse('$kApiBase/api/v1/invitaciones/toggle'), headers: headers)
        .timeout(const Duration(seconds: 15));
    if (!res.ok) throw Exception('Error al cambiar estado del enlace');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

extension on http.Response {
  bool get ok => statusCode >= 200 && statusCode < 300;
}
