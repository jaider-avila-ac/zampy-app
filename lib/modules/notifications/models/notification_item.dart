/// Modelo equivalente al objeto de notificación del backend.
/// Campos idénticos a los usados en NotificationsPage.jsx.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.tipo,
    this.actorNombre,
    this.entidadNombre,
    this.vistaPrevia,
    this.tiempoRelativo = '',
    this.leida = false,
  });

  final int id;
  final String tipo;
  final String? actorNombre;
  final String? entidadNombre;
  final String? vistaPrevia;
  final String tiempoRelativo;
  final bool leida;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: (json['id'] as num).toInt(),
        tipo: (json['tipo'] as String?) ?? '',
        actorNombre: json['actorNombre'] as String?,
        entidadNombre: json['entidadNombre'] as String?,
        vistaPrevia: json['vistaPrevia'] as String?,
        tiempoRelativo: (json['tiempoRelativo'] as String?) ?? '',
        leida: (json['leida'] as bool?) ?? false,
      );

  NotificationItem copyWith({bool? leida}) => NotificationItem(
        id: id,
        tipo: tipo,
        actorNombre: actorNombre,
        entidadNombre: entidadNombre,
        vistaPrevia: vistaPrevia,
        tiempoRelativo: tiempoRelativo,
        leida: leida ?? this.leida,
      );
}
