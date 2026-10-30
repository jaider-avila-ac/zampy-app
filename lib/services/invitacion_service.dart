import 'api_client.dart';

// Equivalente a src/services/invitacionService.js

class InvitacionService {
  InvitacionService._();

  // GET /api/v1/invitaciones/estado
  // { codigoInv, invActivo, pendientes, completadas, detalle[], reaccionesRequeridas,
  //   programaHabilitado, antiguedadHoras, expiraDias }
  static Future<Map<String, dynamic>> getEstado() async {
    final data = await ApiClient.instance.get('/api/v1/invitaciones/estado');
    if (data is! Map) throw Exception('Error al cargar estado de invitaciones');
    return Map<String, dynamic>.from(data);
  }

  // PUT /api/v1/invitaciones/toggle → { invActivo }
  static Future<Map<String, dynamic>> toggleActivo() async {
    final data = await ApiClient.instance.put('/api/v1/invitaciones/toggle');
    if (data is! Map) throw Exception('Error al cambiar estado del enlace');
    return Map<String, dynamic>.from(data);
  }
}
