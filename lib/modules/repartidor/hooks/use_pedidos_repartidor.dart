import '../../../services/pedido_service.dart';
import '../../../services/repartidor_service.dart';
import '../../orders/hooks/pagina_cursor.dart';
import '../models/pedido_repartidor.dart';

/// Los pedidos del repartidor hoy y lo que hace con ellos: tomar uno disponible y avanzar o cancelar los suyos
/// (equivale a useMisPedidosRepartidor + useAccionesRepartidor de React). Tras cada acción se recarga sin spinner.
class UsePedidosRepartidor extends PaginaCursor<PedidoRepartidor> {
  UsePedidosRepartidor(this.menu);

  final String menu;
  MetricasRepartidor metricas = const MetricasRepartidor();
  String? actualizando; // código del pedido con una acción en curso

  List<PedidoRepartidor> get activos => items.where((p) => p.activo).toList();
  List<PedidoRepartidor> get historial => items.where((p) => !p.activo).toList();

  @override
  Future<Map<String, dynamic>> pedir(String? cursor) => RepartidorService.misPedidos(menu, despues: cursor);

  @override
  List<PedidoRepartidor> extraer(Map<String, dynamic> resp) => [
        if (resp['pedidos'] is List)
          for (final p in (resp['pedidos'] as List).whereType<Map>()) PedidoRepartidor.fromJson(Map<String, dynamic>.from(p)),
      ];

  @override
  void alRecibirPrimera(Map<String, dynamic> resp) => metricas = MetricasRepartidor.fromJson(resp);

  Future<void> cargar({bool silencioso = false}) =>
      cargarPagina('No se pudieron cargar los pedidos.', silencioso: silencioso);

  Future<void> cargarMas() => cargarMasPagina('No se pudieron cargar más pedidos.');

  /// null = hecho; si no, el mensaje de error para avisar.
  Future<String?> tomar(String codigo) =>
      _ejecutar(codigo, () => RepartidorService.tomar(codigo), 'El pedido ya no está disponible.');

  Future<String?> cambiarEstado(String codigo, String estado) =>
      _ejecutar(codigo, () => PedidoService.cambiarEstado(codigo, estado), 'No se pudo actualizar el estado.');

  Future<String?> _ejecutar(String codigo, Future<void> Function() accion, String generico) async {
    actualizando = codigo;
    avisar();
    try {
      await accion();
      await cargar(silencioso: true);
      return null;
    } catch (e) {
      return mensaje(e, generico);
    } finally {
      actualizando = null;
      avisar();
    }
  }
}
