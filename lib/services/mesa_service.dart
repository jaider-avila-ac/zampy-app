import 'api_client.dart';

// Equivalente a src/services/mesaService.js (parte del dueño/editor). Las mesas y las cuentas viajan por su código.

Map<String, dynamic> _map(dynamic d) => d is Map ? Map<String, dynamic>.from(d) : {};

class MesaService {
  MesaService._();

  static String _base(String menu) => '/api/v1/menus/$menu/mesas';

  static Future<List<Map<String, dynamic>>> listar(String menu) async {
    final data = await ApiClient.instance.get(_base(menu));
    return data is List ? data.map(_map).toList() : const [];
  }

  static Future<Map<String, dynamic>> crear(String menu, {required String nombre, int? capacidad}) async =>
      _map(await ApiClient.instance.post(_base(menu), body: {'nombre': nombre, 'capacidad': ?capacidad}));

  static Future<Map<String, dynamic>> actualizar(String menu, String mesa, {required String nombre, int? capacidad}) async =>
      _map(await ApiClient.instance.patch('${_base(menu)}/$mesa', body: {'nombre': nombre, 'capacidad': ?capacidad}));

  static Future<Map<String, dynamic>> cambiarActivo(String menu, String mesa, bool activo) async =>
      _map(await ApiClient.instance.patch('${_base(menu)}/$mesa/activo', body: {'activo': activo}));

  static Future<void> eliminar(String menu, String mesa) async {
    await ApiClient.instance.delete('${_base(menu)}/$mesa');
  }

  // ── Mesero ────────────────────────────────────────────────────────────────
  // El dueño o editor también cierra o cancela cualquier cuenta (el mesero que la abrió puede no estar).

  static String _mesero(String menu) => '/api/v1/mesero/$menu';

  /// → { totalCerrado, cantidadRondas, mesaLibre, … }
  static Future<Map<String, dynamic>> cerrarCuenta(String menu, String mesa, String cuenta) async =>
      _map(await ApiClient.instance.post('${_mesero(menu)}/mesas/$mesa/cerrar', query: {'ordenId': cuenta}));

  /// → { mesaLibre, … }
  static Future<Map<String, dynamic>> cancelarCuenta(String menu, String mesa, String cuenta) async =>
      _map(await ApiClient.instance.post('${_mesero(menu)}/mesas/$mesa/cancelar', query: {'ordenId': cuenta}));

  /// Mesas con su ocupación: pedidosActivos, abiertaPorOtro (la tiene otro mesero), cuentasAbiertas…
  static Future<List<Map<String, dynamic>>> mesasMesero(String menu) async {
    final data = await ApiClient.instance.get('${_mesero(menu)}/mesas');
    return data is List ? data.map(_map).toList() : const [];
  }

  /// Las cuentas abiertas de la mesa (varias si se dividió), con sus rondas.
  static Future<List<Map<String, dynamic>>> cuentasDeMesa(String menu, String mesa) async {
    final data = await ApiClient.instance.get('${_mesero(menu)}/mesas/$mesa/cuentas');
    return data is List ? data.map(_map).toList() : const [];
  }

  /// Nueva ronda: a [cuenta] si se indica, a una cuenta nueva y separada si [nuevaCuenta], o a la principal.
  /// [nota]: con cuenta nueva es su nombre ("Juan"; vacío = "Cuenta N"); si no, la nota para cocina.
  /// → { ordenCodigo, referencia, rondaCodigo, duplicado, … }
  static Future<Map<String, dynamic>> agregarRonda(String menu, String mesa,
          {required String requestId, required List<Map<String, dynamic>> items, String? cuenta, bool nuevaCuenta = false, String? nota}) async =>
      _map(await ApiClient.instance.post('${_mesero(menu)}/mesas/$mesa/rondas', body: {
        'requestId': requestId,
        'items': items,
        'ordenCodigo': ?cuenta,
        if (nuevaCuenta) 'nuevaCuenta': true,
        'nota': ?nota,
      }));

  static Future<void> cambiarEstadoRonda(String menu, String ronda, String estado) async {
    await ApiClient.instance.patch('${_mesero(menu)}/rondas/$ronda/estado', body: {'estado': estado});
  }

  static Future<void> registrarAbono(String menu, String mesa, String cuenta,
      {required String requestId, required String medio, required num valor}) async {
    await ApiClient.instance.post('${_mesero(menu)}/mesas/$mesa/cuentas/$cuenta/pagos',
        body: {'requestId': requestId, 'tipo': 'ABONO', 'medio': medio, 'valor': valor});
  }

  /// { rondas, totalRondas, cancelados, totalVendido, totalCobrado }
  static Future<Map<String, dynamic>> misRondas(String menu, String desde, String hasta) async =>
      _map(await ApiClient.instance.get('${_mesero(menu)}/mis-rondas', query: {'desde': desde, 'hasta': hasta}));

  /// { cuentas, siguiente, totalFacturado, totalCobrado, cantidadCuentas }
  static Future<Map<String, dynamic>> misOrdenes(String menu, String desde, String hasta, {String? despues}) async =>
      _map(await ApiClient.instance.get('${_mesero(menu)}/mis-ordenes',
          query: {'desde': desde, 'hasta': hasta, 'despues': ?despues}));
}
