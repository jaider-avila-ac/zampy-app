import 'dart:math';

import 'api_client.dart';

// Equivalente a src/services/pedidoService.js (lado cliente). Los pedidos se identifican por su código.

Map<String, dynamic> _map(dynamic d) => d is Map ? Map<String, dynamic>.from(d) : {};

class PedidoService {
  PedidoService._();

  /// Igual que newRequestId('pedido') de React: un reintento con el mismo id no duplica el pedido.
  static String nuevoRequestId([String prefijo = 'pedido']) {
    final r = Random.secure();
    return '$prefijo:${List.generate(32, (_) => '0123456789abcdef'[r.nextInt(16)]).join()}';
  }

  /// POST /api/v1/pedidos → { codigo, estado, ok, waUrl }
  static Future<Map<String, dynamic>> crear({
    required String menuCodigo,
    required String requestId,
    required List<Map<String, dynamic>> items,
    String? direccionEntrega,
    String? direccionReferencia,
    String? telefono,
  }) async =>
      _map(await ApiClient.instance.post('/api/v1/pedidos', body: {
        'menuCodigo': menuCodigo,
        'requestId': requestId,
        'direccionEntrega': direccionEntrega,
        'direccionReferencia': direccionReferencia,
        'telefono': telefono,
        'items': items,
      }));

  /// GET /api/v1/pedidos/mis-pedidos → { items, siguiente } (cursor; null = no hay más)
  static Future<Map<String, dynamic>> misPedidos({String? despues}) async =>
      _map(await ApiClient.instance.get(
        '/api/v1/pedidos/mis-pedidos',
        query: {'despues': ?despues},
      ));

  static Future<void> marcarRecibido(String codigo) async {
    await ApiClient.instance.patch('/api/v1/pedidos/$codigo/recibido');
  }

  static Future<void> cancelarPedido(String codigo) async {
    await ApiClient.instance.patch('/api/v1/pedidos/$codigo/cancelar');
  }
}
