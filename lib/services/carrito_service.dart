import 'api_client.dart';

// Equivalente a src/services/carritoService.js. El carrito vive en el servidor por menú
// (código del menú publicado); sin sesión o ante cualquier error se ignora, como en React.

class CarritoService {
  CarritoService._();

  static bool get _conSesion {
    final t = ApiClient.instance.tokenProvider?.call();
    return t != null && t.isNotEmpty;
  }

  /// Ítems guardados (`contenido`) o lista vacía.
  static Future<List<Map<String, dynamic>>> get(String menuCodigo) async {
    if (!_conSesion) return [];
    try {
      final data = await ApiClient.instance.get('/api/v1/carrito/$menuCodigo');
      final contenido = data is Map ? data['contenido'] : null;
      return contenido is List
          ? contenido.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(String menuCodigo, List<Map<String, dynamic>> items) async {
    if (!_conSesion) return;
    try {
      await ApiClient.instance.put('/api/v1/carrito/$menuCodigo', body: {'contenido': items});
    } catch (_) {}
  }

  static Future<void> clear(String menuCodigo) async {
    if (!_conSesion) return;
    try {
      await ApiClient.instance.delete('/api/v1/carrito/$menuCodigo');
    } catch (_) {}
  }
}
