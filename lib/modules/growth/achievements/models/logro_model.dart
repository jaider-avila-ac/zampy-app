// Equivalente al shape de logro en React (LogroCard.jsx + useLogros.js), según LogroProgressDto.
class LogroModel {
  final String  codigo;
  final String  nombre;
  final String? descripcion;
  final String  condicion;    // 'ME_ENCANTAS' | 'VISITAS' | 'RESENAS' | 'INVITACIONES'
  final int     cantidad;     // meta
  final int     progreso;     // actual
  final int     diasRecompensa;
  final bool    desbloqueado;
  final String? desbloqueadoEn; // ISO date
  final String? estadoRecompensa; // 'DISPONIBLE' | 'APLICADO'
  final String? aplicadoEn;
  final String? menuCodigoAplicado;

  const LogroModel({
    required this.codigo,
    required this.nombre,
    required this.condicion,
    required this.cantidad,
    required this.progreso,
    required this.diasRecompensa,
    required this.desbloqueado,
    this.descripcion,
    this.desbloqueadoEn,
    this.estadoRecompensa,
    this.aplicadoEn,
    this.menuCodigoAplicado,
  });

  bool get disponible => estadoRecompensa == 'DISPONIBLE';
  bool get aplicado => estadoRecompensa == 'APLICADO';

  factory LogroModel.fromJson(Map<String, dynamic> json) => LogroModel(
        codigo:             (json['codigo'] ?? json['id'])?.toString() ?? '',
        nombre:             json['nombre']   as String?     ?? '',
        descripcion:        json['descripcion'] as String?,
        condicion:          json['condicion'] as String?    ?? '',
        cantidad:           (json['cantidad']   as num?)?.toInt() ?? 0,
        progreso:           (json['progreso']   as num?)?.toInt() ?? 0,
        diasRecompensa:     (json['diasRecompensa'] as num?)?.toInt() ?? 0,
        desbloqueado:       json['desbloqueado'] as bool?   ?? false,
        desbloqueadoEn:     json['desbloqueadoEn']?.toString(),
        estadoRecompensa:   json['estadoRecompensa'] as String?,
        aplicadoEn:         json['aplicadoEn']?.toString(),
        menuCodigoAplicado: json['menuCodigoAplicado'] as String?,
      );
}
