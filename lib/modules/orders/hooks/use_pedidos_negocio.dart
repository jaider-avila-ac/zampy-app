import '../../../services/pedido_service.dart';
import '../models/pedido_negocio.dart';
import 'pagina_cursor.dart';

// Equivale a usePedidosNegocio de React: los pedidos de clientes del menú en un rango, con métricas, cambio de estado,
// valor pagado y repartidor asignado.

class UsePedidosNegocio extends PaginaCursor<PedidoNegocio> {
  UsePedidosNegocio(this.menu) {
    _cargarRepartidores();
  }

  final String menu;
  String _desde = '';
  String _hasta = '';

  MetricasPedidos metricas = const MetricasPedidos();
  List<Repartidor> repartidores = const [];

  /// El pedido que se está actualizando y a qué estado (muestra el spinner en su botón).
  ({String codigo, String estado})? actualizando;

  Future<void> _cargarRepartidores() async {
    try {
      repartidores = (await PedidoService.repartidoresDelMenu(menu)).map(Repartidor.fromJson).toList();
      avisar();
    } catch (_) {
      repartidores = const [];
    }
  }

  @override
  Future<Map<String, dynamic>> pedir(String? cursor) =>
      PedidoService.pedidosDelMenu(menu, _desde, _hasta, despues: cursor);

  @override
  List<PedidoNegocio> extraer(Map<String, dynamic> resp) => [
        if (resp['pedidos'] is List)
          for (final p in (resp['pedidos'] as List).whereType<Map>()) PedidoNegocio.fromJson(Map<String, dynamic>.from(p)),
      ];

  @override
  void alRecibirPrimera(Map<String, dynamic> resp) => metricas = MetricasPedidos.fromJson(resp);

  Future<void> cargar(String desde, String hasta, {bool silencioso = false}) {
    _desde = desde;
    _hasta = hasta;
    return cargarPagina('No se pudieron cargar los pedidos.', silencioso: silencioso);
  }

  Future<void> cargarMas() => cargarMasPagina('No se pudieron cargar más pedidos.');

  void _reemplazar(String codigo, PedidoNegocio Function(PedidoNegocio) cambio) {
    items = [for (final p in items) p.codigo == codigo ? cambio(p) : p];
    avisar();
  }

  /// Ya confirmado por el usuario. Tras el cambio se recarga (el estado afecta las métricas del rango).
  Future<void> cambiarEstado(String codigo, String estado) async {
    actualizando = (codigo: codigo, estado: estado);
    error = null;
    avisar();
    try {
      await PedidoService.cambiarEstado(codigo, estado);
      actualizando = null;
      await cargar(_desde, _hasta, silencioso: true);
    } catch (e) {
      error = mensaje(e, 'No se pudo actualizar el estado.');
    } finally {
      actualizando = null;
      avisar();
    }
  }

  /// Lo guarda ValorPagado; aquí solo se refleja en la lista.
  void valorPagadoGuardado(String codigo, num valor) => _reemplazar(codigo, (p) => p.copyWith(valorPagado: valor));

  Future<void> asignarRepartidor(String codigo, String repartidor) async {
    try {
      final resp = await PedidoService.asignarRepartidor(codigo, repartidor);
      _reemplazar(
        codigo,
        (p) => p.copyWith(
          repartidorCodigo: resp['repartidorCodigo']?.toString() ?? repartidor,
          repartidorNombre: resp['repartidorNombre']?.toString(),
        ),
      );
    } catch (e) {
      error = mensaje(e, 'No se pudo asignar el repartidor.');
      avisar();
    }
  }
}
