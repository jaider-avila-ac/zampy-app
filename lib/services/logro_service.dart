import 'dart:math';

import 'api_client.dart';

// Equivalente a src/services/logroService.js. Los logros y menús viajan por su código público.

class LogroService {
  LogroService._();

  // GET /api/v1/logros — progreso de la cuenta (lanza si falla, para mostrar el error)
  static Future<List<Map<String, dynamic>>> miProgreso() async =>
      _lista(await ApiClient.instance.get('/api/v1/logros'));

  /// POST /api/v1/logros/aplicar — aplica recompensas completas a un menú propio.
  /// [requestId] hace la operación idempotente: reintentar con el mismo id no duplica días.
  /// Devuelve { diasAplicados, menuCodigo, idempotente? }.
  static Future<Map<String, dynamic>> aplicar(
    String menuCodigo,
    List<String> logros,
    String requestId,
  ) async {
    final data = await ApiClient.instance.post(
      '/api/v1/logros/aplicar',
      body: {'menuCodigo': menuCodigo, 'logros': logros, 'requestId': requestId},
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // GET /api/v1/logros/menu/:codigo — logros ya aplicados a ese menú (dueño o editor)
  static Future<List<Map<String, dynamic>>> aplicadosDelMenu(String menuCodigo) async =>
      _lista(await ApiClient.instance.get('/api/v1/logros/menu/$menuCodigo'));

  /// Igual que newRequestId('achievement') de React; el backend acepta [A-Za-z0-9:_-]{8,64}.
  static String nuevoRequestId() {
    final r = Random.secure();
    final hex = List.generate(32, (_) => '0123456789abcdef'[r.nextInt(16)]).join();
    return 'achievement:$hex';
  }

  static List<Map<String, dynamic>> _lista(dynamic data) => data is List
      ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];
}
