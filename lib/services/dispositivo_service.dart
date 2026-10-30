import 'api_client.dart';

// Equivalente a src/services/dispositivoService.js en React.
// Cada sesión se identifica por su `codigo` (DispositivoResponse), nunca por id.

class DispositivoService {
  DispositivoService._();

  // GET /api/v1/dispositivos
  static Future<List<Map<String, dynamic>>> getDispositivos() async {
    final data = await ApiClient.instance.get('/api/v1/dispositivos');
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // DELETE /api/v1/dispositivos/:codigo
  static Future<void> revocar(String codigo) async {
    await ApiClient.instance.delete('/api/v1/dispositivos/$codigo');
  }
}
