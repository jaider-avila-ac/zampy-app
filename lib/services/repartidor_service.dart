import 'api_client.dart';

// Equivalente a src/services/repartidorService.js. El cambio de estado usa PedidoService.cambiarEstado.

Map<String, dynamic> _map(dynamic d) => d is Map ? Map<String, dynamic>.from(d) : {};

class RepartidorService {
  RepartidorService._();

  /// Los pedidos del día: disponibles (sin asignar) y los propios, por páginas.
  /// → { pedidos, siguiente, totalEntregas, cancelados, totalVendido, totalCobrado } (totales de todo el día)
  static Future<Map<String, dynamic>> misPedidos(String menu, {String? despues}) async =>
      _map(await ApiClient.instance.get('/api/v1/repartidor/$menu/mis-pedidos', query: {'despues': ?despues}));

  /// Toma un pedido disponible (falla si otro repartidor ya lo tomó).
  static Future<void> tomar(String pedido) async {
    await ApiClient.instance.patch('/api/v1/pedidos/$pedido/repartidor/tomar');
  }
}
