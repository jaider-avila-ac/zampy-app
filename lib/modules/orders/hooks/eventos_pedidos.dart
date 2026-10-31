import '../../../context/notificacion_context.dart';

/// Llama a [alEvento] cuando llega por WebSocket un evento de pedidos de este menú (nuevo pedido, ronda, mesa abierta
/// o cerrada…); los de otros menús se ignoran (equivale a useEventosPedidos de React). Llamar a [cerrar] en dispose.
class EventosPedidos {
  EventosPedidos(this._notificaciones, this.menu, this.alEvento) : _visto = _notificaciones.pedidosSeq {
    _notificaciones.addListener(_revisar);
  }

  final NotificacionContext _notificaciones;
  final String menu;
  final void Function() alEvento;
  int _visto;

  void _revisar() {
    final seq = _notificaciones.pedidosSeq;
    if (seq == _visto) return; // cambió otra cosa del contexto (badge, suscripción…)
    _visto = seq;
    final deMenu = _notificaciones.pedidosMenuCodigo;
    if (deMenu != null && deMenu != menu) return;
    alEvento();
  }

  void cerrar() => _notificaciones.removeListener(_revisar);
}
