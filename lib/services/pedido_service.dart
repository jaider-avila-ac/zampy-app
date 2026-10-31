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

  // ── Negocio (dueño / editor) ──────────────────────────────────────────────

  static Map<String, String> _rango(String? desde, String? hasta, [String? despues]) =>
      {'desde': ?desde, 'hasta': ?hasta, 'despues': ?despues};

  /// { pedidos, siguiente, totalEntregado, cantidadPedidos, cantEntregados, cantCancelados } (métricas de todo el rango)
  static Future<Map<String, dynamic>> pedidosDelMenu(String menu, String desde, String hasta, {String? despues}) async =>
      _map(await ApiClient.instance.get('/api/v1/pedidos/menu/$menu', query: _rango(desde, hasta, despues)));

  static Future<void> cambiarEstado(String pedido, String estado) async {
    await ApiClient.instance.patch('/api/v1/pedidos/$pedido/estado', body: {'estado': estado});
  }

  static Future<void> registrarValorPagado(String pedido, num valor) async {
    await ApiClient.instance.patch('/api/v1/pedidos/$pedido/valor-pagado', body: {'valor': valor});
  }

  /// [{ codigo, nombre }]: los repartidores son colaboradores del menú y viajan por el código de su usuario.
  static Future<List<Map<String, dynamic>>> repartidoresDelMenu(String menu) async {
    final data = await ApiClient.instance.get('/api/v1/pedidos/menu/$menu/repartidores');
    return data is List ? data.map(_map).toList() : const [];
  }

  /// → { codigo, repartidorCodigo, repartidorNombre, ok }
  static Future<Map<String, dynamic>> asignarRepartidor(String pedido, String repartidor) async =>
      _map(await ApiClient.instance.patch('/api/v1/pedidos/$pedido/repartidor', body: {'repartidor': repartidor}));

  /// Venta total del rango (pedidos de cliente + cuentas de mesa): { totalVentas, totalPedidos, totalCuentas, … }
  static Future<Map<String, dynamic>> resumenVentas(String menu, String desde, String hasta) async =>
      _map(await ApiClient.instance.get('/api/v1/pedidos/menu/$menu/resumen-ventas', query: _rango(desde, hasta)));

  /// Cuentas de mesa CERRADAS: { cuentas, siguiente, totalFacturado, totalCobrado, cantidadCuentas }
  static Future<Map<String, dynamic>> cuentasDelMenu(String menu, String desde, String hasta, {String? despues}) async =>
      _map(await ApiClient.instance.get('/api/v1/pedidos/menu/$menu/cuentas', query: _rango(desde, hasta, despues)));

  /// Mesas abiertas ahora mismo (aparte de las cerradas): { cuentas, totalEnCursoGeneral }
  static Future<Map<String, dynamic>> cuentasEnCursoDelMenu(String menu) async =>
      _map(await ApiClient.instance.get('/api/v1/pedidos/menu/$menu/cuentas-en-curso'));

  /// [{ meseroCodigo, meseroNombre, total, cobrado }] (solo cuentas entregadas del rango)
  static Future<List<Map<String, dynamic>>> ventasPorMesero(String menu, String desde, String hasta) async {
    final data = await ApiClient.instance.get('/api/v1/pedidos/menu/$menu/ventas-por-mesero', query: _rango(desde, hasta));
    return data is List ? data.map(_map).toList() : const [];
  }

  /// Ítem olvidado en una cuenta (queda entregado); items con la forma de toOrderItemPayload.
  static Future<void> agregarItemCuenta(String menu, String cuenta, List<Map<String, dynamic>> items) async {
    await ApiClient.instance.post('/api/v1/pedidos/menu/$menu/cuentas/$cuenta/items',
        body: {'items': items, 'requestId': nuevoRequestId('ajuste')});
  }

  /// Ajuste auditado: tipo CARGO | DESCUENTO; el requestId evita duplicarlo si se reintenta.
  static Future<void> crearAjusteCuenta(String menu, String cuenta,
      {required String tipo, required num valor, required String motivo, required String requestId}) async {
    await ApiClient.instance.post('/api/v1/pedidos/menu/$menu/cuentas/$cuenta/ajustes',
        body: {'tipo': tipo, 'valor': valor, 'motivo': motivo, 'requestId': requestId});
  }

  /// Movimiento de pago auditado: tipo ABONO | REVERSO; medio EFECTIVO | TARJETA | TRANSFERENCIA | OTRO.
  static Future<void> crearMovimientoPagoCuenta(String menu, String cuenta,
      {required String tipo, required String medio, required num valor, String? motivo, required String requestId}) async {
    await ApiClient.instance.post('/api/v1/pedidos/menu/$menu/cuentas/$cuenta/pagos',
        body: {'requestId': requestId, 'tipo': tipo, 'medio': medio, 'valor': valor, 'motivo': motivo});
  }
}
