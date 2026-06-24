// Equivalente al shape de logro en React (LogroCard.jsx + useLogros.js)

class LogroModel {
  final String  id;
  final String  nombre;
  final String? descripcion;
  final String  condicion;    // 'ME_ENCANTAS' | 'VISITAS' | 'RESENAS' | 'INVITACIONES'
  final int     cantidad;     // meta
  final int     progreso;     // actual
  final int     diasRecompensa;
  final bool    desbloqueado;
  final String? desbloqueadoEn; // ISO date

  const LogroModel({
    required this.id,
    required this.nombre,
    required this.condicion,
    required this.cantidad,
    required this.progreso,
    required this.diasRecompensa,
    required this.desbloqueado,
    this.descripcion,
    this.desbloqueadoEn,
  });

  factory LogroModel.fromJson(Map<String, dynamic> json) => LogroModel(
        id:             json['id']?.toString()          ?? '',
        nombre:         json['nombre']   as String?     ?? '',
        descripcion:    json['descripcion'] as String?,
        condicion:      json['condicion'] as String?    ?? '',
        cantidad:       (json['cantidad']   as num?)?.toInt() ?? 0,
        progreso:       (json['progreso']   as num?)?.toInt() ?? 0,
        diasRecompensa: (json['diasRecompensa'] as num?)?.toInt() ?? 0,
        desbloqueado:   json['desbloqueado'] as bool?   ?? false,
        desbloqueadoEn: json['desbloqueadoEn'] as String?,
      );
}
