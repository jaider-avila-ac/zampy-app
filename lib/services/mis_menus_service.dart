import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../modules/dashboard/models/dashboard_models.dart';
import 'api.dart';
import 'api_client.dart';
import 'app_cache.dart';

// Equivalente a menuService.getTarjetas/getResumen/remove/unpublish y
// colaboracionService.misColaboraciones en React. Todas las rutas usan el
// código público del menú, nunca un id numérico.

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

Future<dynamic> _req(
  String method,
  String path, {
  Map<String, String>? extraHeaders,
}) async {
  final headers = await _authHeaders();
  if (extraHeaders != null) headers.addAll(extraHeaders);
  if (!headers.containsKey('Authorization')) {
    throw Exception('Sesión expirada');
  }

  final uri = Uri.parse('$kApiBase$path');
  final http.Response res;
  switch (method) {
    case 'GET':
      res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));
    case 'POST':
      res = await http
          .post(uri, headers: headers)
          .timeout(const Duration(seconds: 20));
    case 'DELETE':
      res = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 20));
    default:
      throw UnsupportedError('Método no soportado: $method');
  }

  if (res.statusCode == 401) {
    await ApiClient.instance.onAuthExpired?.call();
    throw Exception('Sesión expirada');
  }
  if (res.statusCode == 204 || res.body.isEmpty) return null;
  if (res.statusCode < 200 || res.statusCode >= 300) {
    String msg = 'Error ${res.statusCode}';
    try {
      msg = (jsonDecode(res.body) as Map)['message'] as String? ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }
  return jsonDecode(res.body);
}

class MisMenusService {
  MisMenusService._();

  static Future<MisMenusData> getTarjetas() async {
    final data = await _req('GET', '/api/v1/menus/tarjetas');
    return MisMenusData.fromJson(Map<String, dynamic>.from(data as Map));
  }

  static Future<List<ColaboracionMenu>> getColaboraciones() async {
    final data = await _req('GET', '/api/v1/menus/colaboraciones');
    return (data as List? ?? [])
        .whereType<Map>()
        .map((e) => ColaboracionMenu.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<MenuResumen> getResumen(String codigo) async {
    final data = await _req('GET', '/api/v1/menus/$codigo/resumen');
    return MenuResumen.fromJson(Map<String, dynamic>.from(data as Map));
  }

  static Future<String> getDeleteCode(String codigo) async {
    final data = await _req('GET', '/api/v1/menus/$codigo/delete-code');
    final map = Map<String, dynamic>.from(data as Map);
    return (map['code'] ?? map['deleteCode'] ?? '').toString();
  }

  static Future<void> deleteMenu(String codigo, String code) async {
    await _req(
      'DELETE',
      '/api/v1/menus/$codigo',
      extraHeaders: {'X-Delete-Code': code},
    );
  }

  static Future<void> unpublish(String codigo) async {
    await _req('POST', '/api/v1/menus/$codigo/unpublish');
  }

  static void invalidate() {
    AppCache.invalidate('mis_menus');
    AppCache.invalidate('mis_colaboraciones');
  }
}
