import '../../../orders/models/pedido_negocio.dart' show toNum;

/// Una mesa del menú (vista del dueño/editor). Se identifica por su código.
class Mesa {
  const Mesa({
    required this.codigo,
    required this.nombre,
    required this.activo,
    this.capacidad,
    this.pedidosActivos = 0,
  });

  final String codigo;
  final String nombre;
  final int? capacidad;
  final bool activo;
  final int pedidosActivos; // rondas por servir en sus cuentas abiertas

  /// Con pedidos activos no se puede eliminar.
  bool get ocupada => pedidosActivos > 0;

  factory Mesa.fromJson(Map<String, dynamic> j) => Mesa(
        codigo: '${j['codigo'] ?? j['id'] ?? ''}',
        nombre: '${j['nombre'] ?? ''}'.trim().isEmpty ? 'Mesa' : '${j['nombre']}'.trim(),
        capacidad: j['capacidad'] == null ? null : toNum(j['capacidad']).toInt(),
        activo: j['activo'] != false,
        pedidosActivos: toNum(j['pedidosActivos']).toInt(),
      );
}
