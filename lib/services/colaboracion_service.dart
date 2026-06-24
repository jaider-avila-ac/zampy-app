import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

// Equivalente a src/services/colaboracionService.js en React (métodos de transferencia)

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

Future<dynamic> _req(String method, String path) async {
  final headers = await _authHeaders();
  final uri     = Uri.parse('$kApiBase$path');
  final http.Response res;
  switch (method) {
    case 'POST':
      res = await http.post(uri, headers: headers).timeout(const Duration(seconds: 15));
    default:
      throw UnsupportedError('Unsupported method: $method');
  }
  if (res.statusCode == 401) throw Exception('Sesión expirada');
  if (res.statusCode == 204) return null;
  if (res.statusCode < 200 || res.statusCode >= 300) {
    String msg = 'Error ${res.statusCode}';
    try { msg = (jsonDecode(res.body) as Map)['message'] as String? ?? msg; } catch (_) {}
    throw Exception(msg);
  }
  return res.body.isNotEmpty ? jsonDecode(res.body) : null;
}

class ColaboracionService {
  ColaboracionService._();

  // POST /api/v1/menus/:menuId/transferencia/aceptar
  static Future<void> aceptarTransferencia(String menuId) async {
    await _req('POST', '/api/v1/menus/$menuId/transferencia/aceptar');
  }

  // POST /api/v1/menus/:menuId/transferencia/rechazar
  static Future<void> rechazarTransferencia(String menuId) async {
    await _req('POST', '/api/v1/menus/$menuId/transferencia/rechazar');
  }
}
