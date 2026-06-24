import 'package:flutter/material.dart';
import '../../../services/app_cache.dart';
import '../../../services/interaccion_service.dart';
import '../models/notification_model.dart';

// Equivalente a src/modules/notifications/hooks/useNotifications.js en React

const _cacheKey = 'notifications';

class UseNotifications extends ChangeNotifier {
  List<NotificationModel> _items   = [];
  bool                    _loading = true;
  String?                 _error;

  List<NotificationModel> get items   => _items;
  bool                    get loading => _loading;
  String?                 get error   => _error;
  int                     get unread  => _items.where((n) => !n.leida).length;

  Future<void> load() async {
    _error = null;

    // Stale-while-revalidate: mostrar caché inmediatamente
    final cached = AppCache.get(_cacheKey);
    if (cached != null) {
      _items   = (cached as List).map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
      _loading = false;
      notifyListeners();
    } else {
      _loading = true;
      notifyListeners();
    }

    try {
      final raw = await InteraccionService.getNotificaciones();
      AppCache.set(_cacheKey, raw);
      _items = raw.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      AppCache.markStale(_cacheKey);
      if (_items.isEmpty) _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    // Actualización optimista
    _items = _items.map((n) => n.id == id ? n.copyWith(leida: true) : n).toList();
    notifyListeners();
    await InteraccionService.marcarLeida(id);
  }

  Future<void> markAllRead() async {
    await InteraccionService.marcarTodasLeidas();
    _items = _items.map((n) => n.copyWith(leida: true)).toList();
    notifyListeners();
  }

  void deleteNotif(String id) {
    // Optimistic: quitar de lista antes de esperar respuesta del backend
    _items = _items.where((n) => n.id != id).toList();
    notifyListeners();
    InteraccionService.eliminarNotificacion(id);
  }
}
