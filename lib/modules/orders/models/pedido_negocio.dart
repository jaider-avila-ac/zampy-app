import 'dart:convert';

// Un pedido de cliente tal como lo ve el negocio (GET /pedidos/menu/{menú}). Se identifica por su código.

num toNum(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

String? _texto(dynamic v) {
  final s = v?.toString().trim();
  return s == null || s.isEmpty ? null : s;
}

/// Un ítem del pedido: el contenido que armó el cliente (tamaño, personalización, adiciones, grupos) más el precio.
class ItemPedido {
  const ItemPedido({
    required this.nombre,
    required this.cantidad,
    required this.subtotal,
    this.tamano,
    this.personalizacion = const [],
    this.adiciones = const [],
    this.grupos = const [],
    this.nota,
  });

  final String nombre;
  final int cantidad;
  final num subtotal;
  final String? tamano;
  final List<String> personalizacion;
  final List<String> adiciones;
  final List<(String, String)> grupos; // (nombre del grupo, opciones elegidas)
  final String? nota;

  static List<String> _labels(dynamic v) => v is List
      ? v.map((e) => e is Map ? _texto(e['label']) : _texto(e)).whereType<String>().toList()
      : const [];

  factory ItemPedido.fromJson(Map<String, dynamic> j) {
    final precio = j['priceBreakdown'] is Map ? j['priceBreakdown'] as Map : const {};
    final size = j['size'];
    return ItemPedido(
      nombre: _texto(j['productName']) ?? _texto(j['name']) ?? '—',
      cantidad: toNum(j['quantity'] ?? 1).toInt(),
      subtotal: toNum(precio['subtotal']),
      tamano: size is Map ? _texto(size['label']) : null,
      personalizacion: _labels(j['ingredients']),
      adiciones: _labels(j['extras']),
      grupos: [
        if (j['grupos'] is List)
          for (final g in (j['grupos'] as List).whereType<Map>())
            (
              _texto(g['name']) ?? _texto(g['grupoLabel']) ?? 'Grupo',
              g['selectedItems'] is List
                  ? (g['selectedItems'] as List).join(', ')
                  : _labels(g['opciones']).join(', '),
            ),
      ],
      nota: _texto(j['note']),
    );
  }
}

/// Los ítems llegan como lista o, en pedidos antiguos, como JSON en texto.
List<ItemPedido> itemsDePedido(dynamic raw) {
  var lista = raw;
  if (raw is String) {
    try {
      lista = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
  }
  return lista is List
      ? lista.whereType<Map>().map((e) => ItemPedido.fromJson(Map<String, dynamic>.from(e))).toList()
      : const [];
}

/// "2× Hamburguesa, 1× Papas": los dos primeros ítems.
String resumenItems(List<ItemPedido> items) =>
    items.take(2).map((i) => '${i.cantidad}× ${i.nombre}').join(', ');

class PedidoNegocio {
  const PedidoNegocio({
    required this.codigo,
    required this.estado,
    required this.total,
    required this.items,
    this.valorPagado,
    this.creadoEn,
    this.clienteNombre,
    this.clienteTelefono,
    this.direccion,
    this.direccionReferencia,
    this.repartidorCodigo,
    this.repartidorNombre,
  });

  final String codigo;
  final String estado; // pendiente | en_proceso | entregado | cancelado
  final num total;
  final num? valorPagado;
  final List<ItemPedido> items;
  final DateTime? creadoEn;
  final String? clienteNombre;
  final String? clienteTelefono;
  final String? direccion;
  final String? direccionReferencia;
  final String? repartidorCodigo;
  final String? repartidorNombre;

  bool get tieneAcciones => estado == 'pendiente' || estado == 'en_proceso';

  /// Se puede asignar repartidor mientras el pedido siga vivo.
  bool get asignable => estado != 'cancelado' && estado != 'entregado';

  factory PedidoNegocio.fromJson(Map<String, dynamic> j) => PedidoNegocio(
        codigo: '${j['codigo'] ?? j['id'] ?? ''}',
        estado: '${j['estado'] ?? 'pendiente'}',
        total: toNum(j['total']),
        valorPagado: j['valorPagado'] == null ? null : toNum(j['valorPagado']),
        items: itemsDePedido(j['items']),
        creadoEn: DateTime.tryParse('${j['creadoEn'] ?? ''}'),
        clienteNombre: _texto(j['usrNombre']),
        clienteTelefono: _texto(j['usrTelefono']),
        direccion: _texto(j['usrDireccion']),
        direccionReferencia: _texto(j['usrDireccionReferencia']),
        repartidorCodigo: _texto(j['repartidorCodigo'] ?? j['repartidorId']),
        repartidorNombre: _texto(j['repartidorNombre']),
      );

  PedidoNegocio copyWith({num? valorPagado, String? repartidorCodigo, String? repartidorNombre}) => PedidoNegocio(
        codigo: codigo,
        estado: estado,
        total: total,
        valorPagado: valorPagado ?? this.valorPagado,
        items: items,
        creadoEn: creadoEn,
        clienteNombre: clienteNombre,
        clienteTelefono: clienteTelefono,
        direccion: direccion,
        direccionReferencia: direccionReferencia,
        repartidorCodigo: repartidorCodigo ?? this.repartidorCodigo,
        repartidorNombre: repartidorNombre ?? this.repartidorNombre,
      );
}

/// Métricas de todo el rango (no solo de la página cargada).
class MetricasPedidos {
  const MetricasPedidos({this.totalEntregado = 0, this.cantidad = 0, this.cancelados = 0});

  final num totalEntregado; // suma del total de los pedidos entregados
  final int cantidad;
  final int cancelados;

  factory MetricasPedidos.fromJson(Map<String, dynamic> j) => MetricasPedidos(
        totalEntregado: toNum(j['totalEntregado']),
        cantidad: toNum(j['cantidadPedidos']).toInt(),
        cancelados: toNum(j['cantCancelados']).toInt(),
      );
}

class Repartidor {
  const Repartidor(this.codigo, this.nombre);

  final String codigo;
  final String nombre;

  factory Repartidor.fromJson(Map<String, dynamic> j) =>
      Repartidor('${j['codigo'] ?? ''}', _texto(j['nombre']) ?? 'Repartidor');
}

/// Venta total del rango: pedidos de cliente entregados + cuentas de mesa.
class ResumenVentas {
  const ResumenVentas({this.totalVentas = 0, this.totalPedidos = 0, this.totalCuentas = 0});

  final num totalVentas;
  final num totalPedidos;
  final num totalCuentas;

  factory ResumenVentas.fromJson(Map<String, dynamic> j) => ResumenVentas(
        totalVentas: toNum(j['totalVentas']),
        totalPedidos: toNum(j['totalPedidos']),
        totalCuentas: toNum(j['totalCuentas']),
      );
}
