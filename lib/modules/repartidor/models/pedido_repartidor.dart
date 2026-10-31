import '../../orders/models/pedido_negocio.dart';

/// Un pedido en la vista del repartidor. Los datos de entrega (cliente, teléfono, dirección) solo llegan cuando el
/// pedido es suyo ([asignadoAMi]); si está disponible, primero lo toma.
class PedidoRepartidor {
  const PedidoRepartidor(this.pedido, {required this.asignadoAMi});

  final PedidoNegocio pedido;
  final bool asignadoAMi;

  bool get activo => pedido.tieneAcciones;
  bool get disponible => activo && !asignadoAMi;

  factory PedidoRepartidor.fromJson(Map<String, dynamic> j) =>
      PedidoRepartidor(PedidoNegocio.fromJson(j), asignadoAMi: j['asignadoAMi'] == true);
}

/// Totales de todo el día (no solo de la página cargada).
class MetricasRepartidor {
  const MetricasRepartidor({this.entregas = 0, this.cancelados = 0, this.cobrado = 0});

  final int entregas;
  final int cancelados;
  final num cobrado; // lo cobrado registrado en sus entregas

  factory MetricasRepartidor.fromJson(Map<String, dynamic> j) => MetricasRepartidor(
        entregas: toNum(j['totalEntregas']).toInt(),
        cancelados: toNum(j['cancelados']).toInt(),
        cobrado: toNum(j['totalCobrado']),
      );
}
