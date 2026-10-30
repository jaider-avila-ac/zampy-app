// Equivalente al shape de notificación en React (NotificationItem.jsx + useNotifications.js)

class NotificationModel {
  final String codigo;
  final String tipo;
  final String? entidadTipo;
  final String? entidadCodigo;
  final bool leida;
  final String? actorNombre;
  final String? entidadNombre;
  final String? vistaPrevia;
  final String? creadoEn;
  final String? tiempoRelativo;

  const NotificationModel({
    required this.codigo,
    required this.tipo,
    this.entidadTipo,
    this.entidadCodigo,
    required this.leida,
    this.actorNombre,
    this.entidadNombre,
    this.vistaPrevia,
    this.creadoEn,
    this.tiempoRelativo,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        codigo: json['codigo']?.toString() ?? json['id']?.toString() ?? '',
        tipo: (json['tipo'] as String? ?? '').toUpperCase(),
        entidadTipo: json['entidadTipo'] as String?,
        entidadCodigo:
            json['entidadCodigo']?.toString() ?? json['entidadId']?.toString(),
        leida: json['leida'] as bool? ?? false,
        actorNombre: json['actorNombre'] as String?,
        entidadNombre: json['entidadNombre'] as String?,
        vistaPrevia: json['vistaPrevia'] as String?,
        creadoEn: json['creadoEn'] as String?,
        tiempoRelativo: json['tiempoRelativo'] as String?,
      );

  String get id => codigo;
  String? get entidadId => entidadCodigo;

  NotificationModel copyWith({bool? leida}) => NotificationModel(
    codigo: codigo,
    tipo: tipo,
    entidadTipo: entidadTipo,
    entidadCodigo: entidadCodigo,
    leida: leida ?? this.leida,
    actorNombre: actorNombre,
    entidadNombre: entidadNombre,
    vistaPrevia: vistaPrevia,
    creadoEn: creadoEn,
    tiempoRelativo: tiempoRelativo,
  );
}
