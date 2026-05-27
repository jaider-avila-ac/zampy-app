/// Equivalente al objeto de logro devuelto por GET /api/logros.
/// Campos idénticos a los usados en LogrosPage.jsx.
class Logro {
  const Logro({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.condicion,
    required this.cantidad,
    required this.progreso,
    required this.diasRecompensa,
    required this.desbloqueado,
    this.desbloqueadoEn,
  });

  final int id;
  final String nombre;
  final String? descripcion;
  final String condicion; // ME_ENCANTAS | VISITAS | RESENAS | INVITACIONES
  final int cantidad;     // meta
  final int progreso;     // progreso actual
  final int diasRecompensa;
  final bool desbloqueado;
  final DateTime? desbloqueadoEn;

  factory Logro.fromJson(Map<String, dynamic> json) => Logro(
        id: (json['id'] as num).toInt(),
        nombre: (json['nombre'] as String?) ?? '',
        descripcion: json['descripcion'] as String?,
        condicion: (json['condicion'] as String?) ?? '',
        cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
        progreso: (json['progreso'] as num?)?.toInt() ?? 0,
        diasRecompensa: (json['diasRecompensa'] as num?)?.toInt() ?? 0,
        desbloqueado: (json['desbloqueado'] as bool?) ?? false,
        desbloqueadoEn: json['desbloqueadoEn'] == null
            ? null
            : DateTime.tryParse(json['desbloqueadoEn'].toString()),
      );
}
