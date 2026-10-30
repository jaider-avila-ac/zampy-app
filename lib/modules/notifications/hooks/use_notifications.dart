import 'package:flutter/material.dart';
import '../../../services/app_cache.dart';
import '../../../services/interaccion_service.dart';
import '../models/notification_model.dart';

// Equivalente a src/modules/notifications/hooks/useNotifications.js en React

const _cacheKey = 'notifications';

class UseNotifications extends ChangeNotifier {
  List<NotificationModel> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _siguiente;
  String? _error;
  int _version = 0;

  List<NotificationModel> get items => _items;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hayMas => _siguiente != null;
  String? get error => _error;
  int get unread => _items.where((n) => !n.leida).length;

  Future<void> load({bool useCache = true}) async {
    final version = ++_version;
    _error = null;

    if (useCache) {
      final cached = AppCache.get(_cacheKey);
      final cachedItems = _itemsFromCache(cached);
      if (cachedItems != null) {
        _items = cachedItems;
        _loading = false;
        notifyListeners();
      } else {
        _loading = true;
        notifyListeners();
      }
    } else {
      _loading = true;
      notifyListeners();
    }

    try {
      final page = await InteraccionService.getNotificaciones();
      if (version != _version) return;
      _items = _parseItems(page.items);
      _siguiente = page.siguiente;
      AppCache.set(_cacheKey, page.items);
    } catch (e) {
      if (version != _version) return;
      AppCache.markStale(_cacheKey);
      if (_items.isEmpty) _error = _cleanError(e);
    } finally {
      if (version == _version) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() => load(useCache: false);

  Future<void> loadMore() async {
    final cursor = _siguiente;
    if (cursor == null || _loadingMore) return;
    final version = _version;
    _loadingMore = true;
    _error = null;
    notifyListeners();
    try {
      final page = await InteraccionService.getNotificaciones(despues: cursor);
      if (version != _version) return;
      _items = [..._items, ..._parseItems(page.items)];
      _siguiente = page.siguiente;
    } catch (e) {
      if (version == _version) _error = _cleanError(e);
    } finally {
      if (version == _version) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> markRead(String id) async {
    final index = _items.indexWhere((n) => n.codigo == id);
    if (index < 0 || _items[index].leida) return;
    final previous = _items[index];
    _items = [..._items]..[index] = previous.copyWith(leida: true);
    notifyListeners();
    try {
      await InteraccionService.marcarLeida(id);
    } catch (e) {
      if (!_items.any((n) => n.codigo == id)) return;
      final current = _items.indexWhere((n) => n.codigo == id);
      if (current >= 0) {
        _items = [..._items]..[current] = previous;
        notifyListeners();
      }
    }
  }

  Future<void> markAllRead() async {
    try {
      await InteraccionService.marcarTodasLeidas();
      _items = _items.map((n) => n.copyWith(leida: true)).toList();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _cleanError(e);
      notifyListeners();
    }
  }

  void deleteNotif(String id) {
    _items = _items.where((n) => n.codigo != id).toList();
    notifyListeners();
    InteraccionService.eliminarNotificacion(id).catchError((_) {});
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  List<NotificationModel> _parseItems(List<dynamic> raw) {
    return raw
        .whereType<Map>()
        .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<NotificationModel>? _itemsFromCache(dynamic cached) {
    if (cached is List) return _parseItems(cached);
    if (cached is Map && cached['items'] is List) {
      return _parseItems(cached['items'] as List);
    }
    return null;
  }

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
}
