import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_client.dart';

// Equivalente a src/services/estadisticasService.js — registro de vistas y estadísticas del menú

class EstadisticasService {
  EstadisticasService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _viewerKey = '_vt';

  static Future<String> _viewerToken() async {
    try {
      final existing = await _storage.read(key: _viewerKey);
      if (existing != null && existing.isNotEmpty) return existing;

      final random = Random.secure();
      final token = List.generate(
        32,
        (_) => '0123456789abcdef'[random.nextInt(16)],
      ).join();
      await _storage.write(key: _viewerKey, value: token);
      return token;
    } catch (_) {
      return 'anonymous';
    }
  }

  static Future<void> registrarVistaMenu(String slug) async {
    try {
      final token = await _viewerToken();
      await http
          .post(
            Uri.parse('$kApiBase/api/v1/public/menu/$slug/vista'),
            headers: {'X-Viewer-Token': token},
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static Future<void> registrarVistaProducto(
    String slug,
    String productId,
  ) async {
    try {
      final token = await _viewerToken();
      await http
          .post(
            Uri.parse(
              '$kApiBase/api/v1/public/menu/$slug/producto/$productId/vista',
            ),
            headers: {'X-Viewer-Token': token},
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static Map<String, String> _rango(String? desde, String? hasta) => {
    if (desde != null && desde.isNotEmpty) 'desde': desde,
    if (hasta != null && hasta.isNotEmpty) 'hasta': hasta,
  };

  /// GET /api/v1/menus/:codigo/estadisticas — dueño o editor. Sin desde/hasta (YYYY-MM-DD)
  /// trae el histórico completo. { totalVistas, productos[], meEncantas, encantasProductos[],
  /// pedidosDomicilio, rondasMesa, totalOperaciones, conversionOperaciones }
  static Future<Map<String, dynamic>> getEstadisticas(
    String menuCodigo, {
    String? desde,
    String? hasta,
  }) async {
    final data = await ApiClient.instance.get(
      '/api/v1/menus/$menuCodigo/estadisticas',
      query: _rango(desde, hasta),
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  /// GET /api/v1/menus/:codigo/estadisticas/productos — productos más pedidos:
  /// [{ prodCodigo, prodNombre, totalPedidos, totalUnidades, pedidosDomicilio, rondasMesa, ingresos }]
  static Future<List<Map<String, dynamic>>> getEstadisticasProductos(
    String menuCodigo, {
    String? desde,
    String? hasta,
  }) async {
    final data = await ApiClient.instance.get(
      '/api/v1/menus/$menuCodigo/estadisticas/productos',
      query: _rango(desde, hasta),
    );
    return data is List
        ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : [];
  }
}
