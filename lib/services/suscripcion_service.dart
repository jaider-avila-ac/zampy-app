import 'api_client.dart';

// Equivalente a src/services/suscripcionService.js en React.
// La api identifica suscripciones, pagos y menús por su código público: en la app ese código es su
// "id" (rutas /billing/sus/:susId y /billing/:menuCodigo). Igual que conSus/conPago de React, se copia
// codigo → id y menuCodigo → menId para que las pantallas no dependan del nombre del campo.

Map<String, dynamic> conPago(Map<String, dynamic> pago) => {
  ...pago,
  'id': pago['codigo'],
};

Map<String, dynamic> conSus(Map<String, dynamic> sus) => {
  ...sus,
  'id': sus['codigo'],
  'menId': sus['menuCodigo'],
  if (sus['pagos'] is List)
    'pagos': (sus['pagos'] as List)
        .whereType<Map>()
        .map((p) => conPago(Map<String, dynamic>.from(p)))
        .toList(),
};

Map<String, dynamic> _map(dynamic data) =>
    data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

class SuscripcionService {
  SuscripcionService._();

  static final _api = ApiClient.instance;

  /// Precio actual y planes activos (no requiere sesión).
  static Future<Map<String, dynamic>> getPrecio() async =>
      _map(await _api.get('/api/v1/suscripciones/precio', auth: false));

  static Future<List<Map<String, dynamic>>> getMisSuscripciones() async {
    final data = await _api.get('/api/v1/suscripciones');
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((s) => conSus(Map<String, dynamic>.from(s)))
        .toList();
  }

  static Future<Map<String, dynamic>> getMiSuscripcionById(String susId) async =>
      conSus(_map(await _api.get('/api/v1/suscripciones/$susId')));

  /// null si el menú aún no tiene suscripción.
  static Future<Map<String, dynamic>?> getMiSuscripcion(String menId) async {
    try {
      final data = await _api.get('/api/v1/suscripciones/menus/$menId');
      return data is Map ? conSus(Map<String, dynamic>.from(data)) : null;
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  /// Página de pagos: { items, siguiente } (cursor; null si no hay más).
  static Future<Map<String, dynamic>> getMisPagos(
    String menId, {
    String? despues,
  }) async {
    final r = _map(
      await _api.get(
        '/api/v1/suscripciones/menus/$menId/pagos',
        query: {'despues': ?despues},
      ),
    );
    return {
      ...r,
      'items': (r['items'] as List? ?? [])
          .whereType<Map>()
          .map((p) => conPago(Map<String, dynamic>.from(p)))
          .toList(),
    };
  }

  /// Renueva el mismo plan. Devuelve { checkoutUrl, referencia, montoCentavos, ... }.
  static Future<Map<String, dynamic>> iniciarPago(String menId) async =>
      _map(await _api.post('/api/v1/suscripciones/menus/$menId/pagar'));

  /// Compra de un plan (o cambio).
  static Future<Map<String, dynamic>> iniciarCheckout(
    String menId, [
    String? plan,
  ]) async => _map(
    await _api.post(
      '/api/v1/suscripciones/menus/$menId/checkout',
      body: {'plan': ?plan},
    ),
  );

  static Future<Map<String, dynamic>> iniciarUpgrade(String menId) async =>
      _map(await _api.post('/api/v1/suscripciones/menus/$menId/upgrade'));

  /// Pago integrado con tarjeta tokenizada. Devuelve { wompiTxId, status, mensaje }.
  static Future<Map<String, dynamic>> pagarConTarjeta(
    String menId, {
    required String tipoPlan,
    required String cardToken,
    required String acceptanceToken,
    required String personalAuthToken,
  }) async => _map(
    await _api.post(
      '/api/v1/suscripciones/menus/$menId/pagar-con-tarjeta',
      body: {
        'tipoPlan': tipoPlan,
        'cardToken': cardToken,
        'acceptanceToken': acceptanceToken,
        'personalAuthToken': personalAuthToken,
      },
    ),
  );

  // ── Cobro automático ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAcceptanceTokens() async =>
      _map(await _api.get('/api/v1/suscripciones/acceptance-tokens'));

  static Future<void> guardarFuentePago(
    String susId,
    String cardToken,
    String acceptanceToken,
    String personalAuthToken,
  ) async {
    await _api.post(
      '/api/v1/suscripciones/$susId/fuente-pago',
      body: {
        'cardToken': cardToken,
        'acceptanceToken': acceptanceToken,
        'personalAuthToken': personalAuthToken,
      },
    );
  }

  static Future<void> eliminarFuentePago(String susId) async {
    await _api.delete('/api/v1/suscripciones/$susId/fuente-pago');
  }

  static Future<void> toggleCobroAuto(String susId, bool enabled) async {
    await _api.patch(
      '/api/v1/suscripciones/$susId/cobro-auto',
      body: {'enabled': enabled},
    );
  }

  static Future<void> cancelarSuscripcion(String menId) async {
    await _api.delete('/api/v1/suscripciones/menus/$menId');
  }

  /// Cancela al fin del período pagado.
  static Future<void> cancelarAlFin(String susId) async {
    await _api.post('/api/v1/suscripciones/$susId/cancelar');
  }
}
