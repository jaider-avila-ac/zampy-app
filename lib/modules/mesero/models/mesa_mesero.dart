import '../../orders/models/pedido_negocio.dart' show toNum;

/// Una mesa en la vista del mesero: ocupación, si la atiende otro mesero y cuántas cuentas tiene abiertas.
class MesaMesero {
  const MesaMesero({
    required this.codigo,
    required this.nombre,
    this.capacidad,
    this.pedidosActivos = 0,
    this.abiertaPorOtro = false,
    this.atendidaPor,
    this.cuentasAbiertas = 0,
  });

  final String codigo;
  final String nombre;
  final int? capacidad;
  final int pedidosActivos; // rondas por servir
  final bool abiertaPorOtro; // la cuenta principal es de otro mesero: no se puede abrir
  final String? atendidaPor;
  final int cuentasAbiertas;

  bool get dividida => cuentasAbiertas > 1;

  factory MesaMesero.fromJson(Map<String, dynamic> j) => MesaMesero(
        codigo: '${j['codigo'] ?? j['id'] ?? ''}',
        nombre: '${j['nombre'] ?? 'Mesa'}',
        capacidad: j['capacidad'] == null ? null : toNum(j['capacidad']).toInt(),
        pedidosActivos: toNum(j['pedidosActivos']).toInt(),
        abiertaPorOtro: j['abiertaPorOtro'] == true,
        atendidaPor: j['abiertaPorMeseroNombre']?.toString(),
        cuentasAbiertas: j['cuentasAbiertas'] is List ? (j['cuentasAbiertas'] as List).length : 0,
      );
}
