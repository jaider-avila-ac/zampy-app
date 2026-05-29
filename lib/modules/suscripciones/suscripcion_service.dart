import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';
import 'suscripcion_detalle_model.dart';
import 'suscripcion_model.dart';

class SuscripcionService {
  SuscripcionService._();

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<MenuConSuscripcion>> getMenus() async {
    try {
      final res = await http
          .get(Uri.parse('$kApiBase/api/menus'), headers: await _headers())
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(MenuConSuscripcion.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Precio?> getPrecio() async {
    try {
      final res = await http
          .get(Uri.parse('$kApiBase/api/suscripciones/precio'),
              headers: await _headers())
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      return Precio.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> iniciarPago(int menId) async {
    try {
      final res = await http
          .post(Uri.parse('$kApiBase/api/suscripciones/menus/$menId/pagar'),
              headers: await _headers())
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['checkoutUrl'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<SuscripcionDetalle?> getMiSuscripcion(int menId) async {
    try {
      final res = await http
          .get(Uri.parse('$kApiBase/api/suscripciones/menus/$menId'),
              headers: await _headers())
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      return SuscripcionDetalle.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // plan: 'basico' | 'avanzado' | null (null = prueba gratuita)
  static Future<String?> iniciarCheckout(int menId, String? plan) async {
    try {
      final body = plan != null ? jsonEncode({'plan': plan}) : jsonEncode({});
      final headers = await _headers();
      final res = await http
          .post(
            Uri.parse('$kApiBase/api/suscripciones/menus/$menId/checkout'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['checkoutUrl'] as String?;
    } catch (_) {
      return null;
    }
  }
}
