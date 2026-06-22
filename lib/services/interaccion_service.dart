import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

// Equivalente a src/services/interaccionService.js en React

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

class InteraccionService {
  InteraccionService._();

  // POST /api/v1/interacciones/menu/:slug/me-encanta
  static Future<Map<String, dynamic>?> toggleEncanta(String slug) async {
    try {
      final headers = await _authHeaders();
      final res = await http
          .post(Uri.parse('$kApiBase/api/v1/interacciones/menu/$slug/me-encanta'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 204) return null;
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // GET /api/v1/interacciones/mis-encantados
  static Future<List<int>> misEncantados() async {
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('Authorization')) return [];
      final res = await http
          .get(Uri.parse('$kApiBase/api/v1/interacciones/mis-encantados'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list.map((e) => (e as num).toInt()).toList();
    } catch (_) {
      return [];
    }
  }

  // GET /api/v1/public/menu/:slug/resumen
  static Future<Map<String, dynamic>?> getResumen(String slug) async {
    try {
      final res = await http
          .get(Uri.parse('$kApiBase/api/v1/public/menu/$slug/resumen'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // GET /api/v1/public/menu/:slug/resenas
  static Future<List<dynamic>> getResenas(String slug) async {
    try {
      final res = await http
          .get(Uri.parse('$kApiBase/api/v1/public/menu/$slug/resenas'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      return jsonDecode(res.body) as List;
    } catch (_) {
      return [];
    }
  }

  // GET /api/v1/notificaciones/sin-leer
  static Future<int> getSinLeer() async {
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('Authorization')) return 0;
      final res = await http
          .get(Uri.parse('$kApiBase/api/v1/notificaciones/sin-leer'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return 0;
      final data = jsonDecode(res.body);
      if (data is int) return data;
      if (data is Map) return (data['count'] as num?)?.toInt() ?? 0;
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
