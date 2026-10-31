import 'pedido_negocio.dart' show toNum;

// Una cuenta (orden) de mesa: sus rondas, los ajustes auditados y los movimientos de pago. Viaja por su código y el
// de su mesa.

String? _texto(dynamic v) {
  final s = v?.toString().trim();
  return s == null || s.isEmpty ? null : s;
}

List<Map<String, dynamic>> _lista(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

class ItemRonda {
  const ItemRonda({required this.cantidad, required this.nombre, this.precioUnit = 0, this.detalle, this.nota});

  final int cantidad;
  final String nombre;
  final num precioUnit;
  final String? detalle;
  final String? nota;

  factory ItemRonda.fromJson(Map<String, dynamic> j) => ItemRonda(
        cantidad: toNum(j['cantidad'] ?? 1).toInt(),
        nombre: _texto(j['prodNombre']) ?? '—',
        precioUnit: toNum(j['precioUnit']),
        detalle: _texto(j['detalle']),
        nota: _texto(j['nota']),
      );
}

class RondaCuenta {
  const RondaCuenta({
    this.codigo = '',
    required this.estado,
    required this.total,
    this.nota,
    this.items = const [],
    this.creadoEn,
    this.mesaNombre,
  });

  final String codigo;
  final String estado; // pendiente | en_proceso | entregado | cancelado
  final num total;
  final String? nota;
  final List<ItemRonda> items;
  final DateTime? creadoEn;
  final String? mesaNombre; // solo en el historial del mesero

  /// Todavía se puede avanzar o cancelar.
  bool get activa => estado == 'pendiente' || estado == 'en_proceso';

  factory RondaCuenta.fromJson(Map<String, dynamic> j) => RondaCuenta(
        codigo: '${j['codigo'] ?? j['id'] ?? ''}',
        estado: '${j['estado'] ?? ''}',
        total: toNum(j['total']),
        nota: _texto(j['nota']),
        items: _lista(j['items']).map(ItemRonda.fromJson).toList(),
        creadoEn: DateTime.tryParse('${j['creadoEn'] ?? ''}'),
        mesaNombre: _texto(j['mesaNombre']),
      );
}

/// Cargo o descuento auditado (no altera la cuenta original).
class AjusteCuenta {
  const AjusteCuenta({required this.esCargo, required this.valor, required this.motivo, this.actor});

  final bool esCargo;
  final num valor;
  final String motivo;
  final String? actor;

  factory AjusteCuenta.fromJson(Map<String, dynamic> j) => AjusteCuenta(
        esCargo: j['tipo'] == 'CARGO',
        valor: toNum(j['valor']),
        motivo: _texto(j['motivo']) ?? '',
        actor: _texto(j['actorNombre']),
      );
}

/// Abono (cobro) o reverso (devolución) auditado.
class PagoCuenta {
  const PagoCuenta({required this.esAbono, required this.medio, required this.valor, this.actor});

  final bool esAbono;
  final String medio;
  final num valor;
  final String? actor;

  factory PagoCuenta.fromJson(Map<String, dynamic> j) => PagoCuenta(
        esAbono: j['tipo'] == 'ABONO',
        medio: '${j['medio'] ?? ''}',
        valor: toNum(j['valor']),
        actor: _texto(j['actorNombre']),
      );
}

class CuentaMesa {
  const CuentaMesa({
    required this.codigo,
    required this.mesaCodigo,
    required this.mesaNombre,
    required this.total,
    required this.totalEnCurso,
    required this.saldoPendiente,
    this.totalPagado = 0,
    this.referencia,
    this.meseroNombre,
    this.abiertaEn,
    this.cerradaEn,
    this.rondas = const [],
    this.ajustes = const [],
    this.pagos = const [],
  });

  final String codigo;
  final String mesaCodigo;
  final String mesaNombre;
  final String? referencia; // cuenta dividida ("Juan", "Cuenta 2"…)
  final String? meseroNombre;
  final DateTime? abiertaEn;
  final DateTime? cerradaEn;
  final num total;
  final num totalEnCurso;
  final num saldoPendiente;
  final num totalPagado;
  final List<RondaCuenta> rondas;
  final List<AjusteCuenta> ajustes;
  final List<PagoCuenta> pagos;

  bool get conSaldo => saldoPendiente != 0;

  factory CuentaMesa.fromJson(Map<String, dynamic> j) => CuentaMesa(
        codigo: '${j['codigo'] ?? j['id'] ?? ''}',
        mesaCodigo: '${j['mesaCodigo'] ?? j['mesaId'] ?? ''}',
        mesaNombre: _texto(j['mesaNombre']) ?? 'Mesa',
        referencia: _texto(j['referencia']),
        meseroNombre: _texto(j['meseroNombre']),
        abiertaEn: DateTime.tryParse('${j['abiertaEn'] ?? ''}'),
        cerradaEn: DateTime.tryParse('${j['cerradaEn'] ?? ''}'),
        total: toNum(j['total']),
        totalEnCurso: toNum(j['totalEnCurso']),
        saldoPendiente: toNum(j['saldoPendiente']),
        totalPagado: toNum(j['totalPagado']),
        rondas: _lista(j['rondas']).map(RondaCuenta.fromJson).toList(),
        ajustes: _lista(j['ajustes']).map(AjusteCuenta.fromJson).toList(),
        pagos: _lista(j['pagos']).map(PagoCuenta.fromJson).toList(),
      );
}

class VentaMesero {
  const VentaMesero(this.codigo, this.nombre, this.total);

  final String codigo;
  final String nombre;
  final num total;

  factory VentaMesero.fromJson(Map<String, dynamic> j) =>
      VentaMesero('${j['meseroCodigo'] ?? ''}', _texto(j['meseroNombre']) ?? 'Mesero', toNum(j['total']));
}
