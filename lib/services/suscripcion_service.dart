import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

// Equivalente a src/services/suscripcionService.js en React

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
  String path, [
  Map<String, dynamic>? body,
]) async {
  final headers = await _authHeaders();
  final uri = Uri.parse('$kApiBase$path');
  final http.Response res;

  switch (method) {
    case 'GET':
      res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    case 'POST':
      res = await http.post(uri, headers: headers,
          body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 30));
    case 'PATCH':
      res = await http.patch(uri, headers: headers,
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

class SuscripcionService {
  SuscripcionService._();

  static Future<Map<String, dynamic>> getPrecio() async {
    final data = await _req('GET', '/api/v1/suscripciones/precio');
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getEstadoPasarela() async {
    final data = await _req('GET', '/api/v1/suscripciones/estado-pasarela');
    return data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getMisSuscripciones() async {
    final data = await _req('GET', '/api/v1/suscripciones');
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getMiSuscripcionById(int susId) async {
    final data = await _req('GET', '/api/v1/suscripciones/$susId');
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getMiSuscripcion(int menuId) async {
    try {
      final data = await _req('GET', '/api/v1/suscripciones/menus/$menuId');
      return data as Map<String, dynamic>?;
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('Error 404')) return null;
      rethrow;
    }
  }

  static Future<List<dynamic>> getMisPagos(int menuId) async {
    final data = await _req('GET', '/api/v1/suscripciones/menus/$menuId/pagos');
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> iniciarPago(int menuId) async {
    final data = await _req('POST', '/api/v1/suscripciones/menus/$menuId/pagar');
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> iniciarCheckout(int menuId, [String? plan]) async {
    final data = await _req('POST', '/api/v1/suscripciones/menus/$menuId/checkout',
        plan != null ? {'plan': plan} : {});
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> iniciarUpgrade(int menuId) async {
    final data = await _req('POST', '/api/v1/suscripciones/menus/$menuId/upgrade');
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> pagarConTarjeta(
    int menuId, {
    required String tipoPlan,
    required String cardToken,
    required String acceptanceToken,
    required String personalAuthToken,
  }) async {
    final data = await _req('POST', '/api/v1/suscripciones/menus/$menuId/pagar-con-tarjeta', {
      'tipoPlan': tipoPlan,
      'cardToken': cardToken,
      'acceptanceToken': acceptanceToken,
      'personalAuthToken': personalAuthToken,
    });
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAcceptanceTokens() async {
    final data = await _req('GET', '/api/v1/suscripciones/acceptance-tokens');
    return data as Map<String, dynamic>;
  }

  static Future<void> guardarFuentePago(
      int susId, String cardToken, String acceptanceToken, String personalAuthToken) async {
    await _req('POST', '/api/v1/suscripciones/$susId/fuente-pago', {
      'cardToken': cardToken,
      'acceptanceToken': acceptanceToken,
      'personalAuthToken': personalAuthToken,
    });
  }

  static Future<void> eliminarFuentePago(int susId) async {
    await _req('DELETE', '/api/v1/suscripciones/$susId/fuente-pago');
  }

  static Future<void> toggleCobroAuto(int susId, bool enabled) async {
    await _req('PATCH', '/api/v1/suscripciones/$susId/cobro-auto', {'enabled': enabled});
  }

  static Future<void> cancelarSuscripcion(int menuId) async {
    await _req('DELETE', '/api/v1/suscripciones/menus/$menuId');
  }

  static Future<void> cancelarAlFin(int susId) async {
    await _req('POST', '/api/v1/suscripciones/$susId/cancelar');
  }
}
