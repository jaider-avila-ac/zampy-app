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

  // GET /api/v1/interacciones/menu/:slug/resenas (con auth — devuelve esPropia)
  static Future<List<dynamic>> misResenas(String slug) async {
    try {
      final headers = await _authHeaders();
      final res = await http
          .get(Uri.parse('$kApiBase/api/v1/interacciones/menu/$slug/resenas'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      return jsonDecode(res.body) as List;
    } catch (_) {
      return [];
    }
  }

  // POST /api/v1/interacciones/menu/:slug/resena
  static Future<Map<String, dynamic>?> crearResena(String slug, String texto) async {
    try {
      final headers = await _authHeaders();
      final res = await http
          .post(
            Uri.parse('$kApiBase/api/v1/interacciones/menu/$slug/resena'),
            headers: headers,
            body: jsonEncode({'texto': texto}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 204) return null;
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final body = res.body;
        String msg = 'Error ${res.statusCode}';
        try { msg = (jsonDecode(body) as Map)['message'] as String? ?? msg; } catch (_) {}
        throw Exception(msg);
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // DELETE /api/v1/interacciones/menu/:slug/resena
  static Future<void> eliminarResena(String slug) async {
    try {
      final headers = await _authHeaders();
      await http
          .delete(Uri.parse('$kApiBase/api/v1/interacciones/menu/$slug/resena'), headers: headers)
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // GET /api/v1/interacciones/menu/:slug/me-encanta (estado del usuario actual)
  static Future<Map<String, dynamic>?> estadoEncanta(String slug) async {
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('Authorization')) return null;
      final res = await http
          .get(Uri.parse('$kApiBase/api/v1/interacciones/menu/$slug/me-encanta'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // POST /api/v1/interacciones/menu/:slug/productos/:prodId/calificar
  static Future<Map<String, dynamic>?> calificar(String slug, String prodId, int estrellas) async {
    try {
      final headers = await _authHeaders();
      final res = await http
          .post(
            Uri.parse('$kApiBase/api/v1/interacciones/menu/$slug/productos/$prodId/calificar'),
            headers: headers,
            body: jsonEncode({'estrellas': estrellas}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 204) return null;
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // GET /api/v1/interacciones/menu/:slug/productos/:prodId/mi-calificacion
  static Future<Map<String, dynamic>?> miCalificacion(String slug, String prodId) async {
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('Authorization')) return null;
      final res = await http
          .get(
            Uri.parse('$kApiBase/api/v1/interacciones/menu/$slug/productos/$prodId/mi-calificacion'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
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

  // GET /api/v1/notificaciones
  static Future<List<dynamic>> getNotificaciones() async {
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('Authorization')) return [];
      final res = await http
          .get(Uri.parse('$kApiBase/api/v1/notificaciones'), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      return jsonDecode(res.body) as List;
    } catch (_) {
      return [];
    }
  }

  // PUT /api/v1/notificaciones/:id/leida
  static Future<void> marcarLeida(String id) async {
    try {
      final headers = await _authHeaders();
      await http
          .put(Uri.parse('$kApiBase/api/v1/notificaciones/$id/leida'), headers: headers)
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // PUT /api/v1/notificaciones/leer-todas
  static Future<void> marcarTodasLeidas() async {
    final headers = await _authHeaders();
    final res = await http
        .put(Uri.parse('$kApiBase/api/v1/notificaciones/leer-todas'), headers: headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Error ${res.statusCode}';
      try { msg = (jsonDecode(res.body) as Map)['message'] as String? ?? msg; } catch (_) {}
      throw Exception(msg);
    }
  }

  // DELETE /api/v1/notificaciones/:id
  static Future<void> eliminarNotificacion(String id) async {
    try {
      final headers = await _authHeaders();
      await http
          .delete(Uri.parse('$kApiBase/api/v1/notificaciones/$id'), headers: headers)
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
