import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

// Equivalente a menuService.getAll() y colaboracionService.misColaboraciones() en React

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

class MisMenusService {
  MisMenusService._();

  // GET /api/v1/menus
  static Future<List<dynamic>> getAll() async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('$kApiBase/api/v1/menus'), headers: headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 401) throw Exception('Sesión expirada');
    if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
    return jsonDecode(res.body) as List;
  }

  // GET /api/v1/menus/colaboraciones
  static Future<List<dynamic>> misColaboraciones() async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('$kApiBase/api/v1/menus/colaboraciones'), headers: headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 401) throw Exception('Sesión expirada');
    if (res.statusCode != 200) throw Exception('Error ${res.statusCode}');
    return jsonDecode(res.body) as List;
  }
}
