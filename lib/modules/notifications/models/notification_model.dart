// Equivalente al shape de notificación en React (NotificationItem.jsx + useNotifications.js)

class NotificationModel {
  final String  id;
  final String  tipo;
  final bool    leida;
  final String? actorNombre;
  final String? entidadId;      // menuId — usado en transferencias y billing
  final String? entidadNombre;
  final String? tiempoRelativo;

  const NotificationModel({
    required this.id,
    required this.tipo,
    required this.leida,
    this.actorNombre,
    this.entidadId,
    this.entidadNombre,
    this.tiempoRelativo,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id:             json['id']?.toString()             ?? '',
        tipo:           json['tipo']  as String?           ?? '',
        leida:          json['leida'] as bool?             ?? false,
        actorNombre:    json['actorNombre']  as String?,
        entidadId:      json['entidadId']?.toString(),
        entidadNombre:  json['entidadNombre'] as String?,
        tiempoRelativo: json['tiempoRelativo'] as String?,
      );

  NotificationModel copyWith({bool? leida}) => NotificationModel(
        id:             id,
        tipo:           tipo,
        leida:          leida ?? this.leida,
        actorNombre:    actorNombre,
        entidadId:      entidadId,
        entidadNombre:  entidadNombre,
        tiempoRelativo: tiempoRelativo,
      );
}
