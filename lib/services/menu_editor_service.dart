import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

// Equivalente a src/services/menuService.js + colaboracionService.js en React
// Todas las llamadas de edición de menús requieren autenticación.

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

Future<String?> _getToken() async {
  try {
    final raw = await _storage.read(key: 'auth');
    if (raw == null) return null;
    return (jsonDecode(raw) as Map<String, dynamic>)['token'] as String?;
  } catch (_) {
    return null;
  }
}

Future<dynamic> _req(
  String method,
  String path, [
  Map<String, dynamic>? body,
  Map<String, String>? extra,
]) async {
  final headers = await _authHeaders();
  if (extra != null) headers.addAll(extra);
  final uri = Uri.parse('$kApiBase$path');
  final http.Response res;

  switch (method) {
    case 'GET':
      res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    case 'POST':
      res = await http.post(uri, headers: headers,
          body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 30));
    case 'PUT':
      res = await http.put(uri, headers: headers,
          body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 30));
    case 'DELETE':
      res = await http.delete(uri, headers: headers)
          .timeout(const Duration(seconds: 30));
    default:
      throw UnsupportedError('Method not supported: $method');
  }

  if (res.statusCode == 401) throw Exception('Sesión expirada');
  if (res.statusCode == 204) return null;
  if (res.statusCode < 200 || res.statusCode >= 300) {
    String msg = 'Error ${res.statusCode}';
    try {
      msg = (jsonDecode(res.body) as Map)['message'] as String? ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }
  return res.body.isNotEmpty ? jsonDecode(res.body) : null;
}

class MenuEditorService {
  MenuEditorService._();

  // ── Menú ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getById(int id) async {
    final data = await _req('GET', '/api/v1/menus/$id');
    return data as Map<String, dynamic>;
  }

  // PUT /api/v1/menus/:id/draft con patch parcial
  // patch puede tener: info, categories, products, grupos, design, restaurantCategoryId
  static Future<Map<String, dynamic>> updateDraft(
      int id, Map<String, dynamic> patch) async {
    final data = await _req('PUT', '/api/v1/menus/$id/draft', patch);
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> publish(int id, {bool trial = false}) async {
    final path = trial ? '/api/v1/menus/$id/publish?trial=true' : '/api/v1/menus/$id/publish';
    final data = await _req('POST', path);
    return data as Map<String, dynamic>;
  }

  static Future<void> unpublish(int id) async {
    await _req('POST', '/api/v1/menus/$id/unpublish');
  }

  static Future<String> getDeleteCode(int id) async {
    final data = await _req('GET', '/api/v1/menus/$id/delete-code') as Map<String, dynamic>;
    return data['code'] as String? ?? data['deleteCode'] as String? ?? '';
  }

  static Future<void> deleteMenu(int id, String code) async {
    final headers = await _authHeaders();
    headers['X-Delete-Code'] = code;
    final uri = Uri.parse('$kApiBase/api/v1/menus/$id');
    final res = await http.delete(uri, headers: headers)
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 401) throw Exception('Sesión expirada');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Error ${res.statusCode}';
      try {
        msg = (jsonDecode(res.body) as Map)['message'] as String? ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // POST /api/v1/menus — crea un nuevo menú y devuelve el menú creado con su ID
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final result = await _req('POST', '/api/v1/menus', data);
    return result as Map<String, dynamic>;
  }

  // ── Slug ──────────────────────────────────────────────────────────────────

  // Verifica si un slug está disponible. excludeId=null para creación nueva.
  static Future<bool> checkSlug(String slug, [int? excludeId]) async {
    try {
      final exclude = excludeId != null ? '&excludeId=$excludeId' : '';
      final uri = Uri.parse(
        '$kApiBase/api/v1/public/slugs/check?slug=${Uri.encodeComponent(slug)}$exclude',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (!res.ok) return true;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['available'] as bool? ?? true;
    } catch (_) {
      return true;
    }
  }

  // ── Colaboradores ─────────────────────────────────────────────────────────

  static Future<List<dynamic>> listarColaboradores(int menuId) async {
    final data = await _req('GET', '/api/v1/menus/$menuId/colaboradores');
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> invitarColaborador(
      int menuId, String codigo) async {
    final data = await _req(
        'POST', '/api/v1/menus/$menuId/colaboradores', {'codigo': codigo});
    return data as Map<String, dynamic>;
  }

  static Future<void> eliminarColaborador(int menuId, int userId) async {
    final headers = await _authHeaders();
    final uri =
        Uri.parse('$kApiBase/api/v1/menus/$menuId/colaboradores/$userId');
    final res = await http.delete(uri, headers: headers)
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 401) throw Exception('Sesión expirada');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Error ${res.statusCode}';
      try {
        msg = (jsonDecode(res.body) as Map)['message'] as String? ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> transferirMenu(
      int menuId, String codigo) async {
    final data = await _req(
        'POST', '/api/v1/menus/$menuId/transferir', {'codigo': codigo});
    return (data ?? {}) as Map<String, dynamic>;
  }

  // ── Imágenes ──────────────────────────────────────────────────────────────

  // Sube una imagen como multipart. tipo: 'logo' | 'banner' | 'producto'
  // Retorna la URL pública, o null si falla (el usuario puede escribir URL manual).
  static Future<String?> uploadImage(int menuId, File imageFile, String tipo) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$kApiBase/api/v1/menus/$menuId/upload');
      final req = http.MultipartRequest('POST', uri);
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      req.fields['tipo'] = tipo;
      req.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) return null;
      final body = await streamed.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['url'] as String?;
    } catch (_) {
      return null;
    }
  }
}

extension on http.Response {
  bool get ok => statusCode >= 200 && statusCode < 300;
}
