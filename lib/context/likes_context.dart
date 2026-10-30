import 'package:flutter/material.dart';

import '../context/auth_context.dart';
import '../services/interaccion_service.dart';

// Equivalente a src/hooks/useEncantados.js en React.
// Mantiene el estado de "me encanta" de menús y productos para toda la app.

class LikesContext extends ChangeNotifier {
  Set<String> _menus = {};
  Set<String> _productos = {};
  String? _userKey;
  bool _loaded = false;
  Future<void>? _loading;

  Set<String> get menuIds => _menus;
  Set<String> get productIds => _productos;
  bool get conSesion => _userKey != null;

  bool menuLiked(String codigo) => _menus.contains(codigo);
  bool productLiked(String codigo) => _productos.contains(codigo);

  Future<void> updateFromAuth(AuthContext auth) {
    final key = auth.isLoggedIn
        ? (auth.userCode ?? auth.email ?? auth.token)
        : null;

    if (key == _userKey && (_loaded || _loading != null)) {
      return _loading ?? Future.value();
    }

    _userKey = key;
    _menus = {};
    _productos = {};
    _loaded = false;
    _loading = null;

    if (key == null) {
      notifyListeners();
      return Future.value();
    }

    final future = _load();
    _loading = future;
    return future;
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        InteraccionService.misEncantados(),
        InteraccionService.misProductosEncantados(),
      ]);
      _menus = results[0].toSet();
      _productos = results[1].toSet();
      _loaded = true;
    } catch (_) {
      _menus = {};
      _productos = {};
    } finally {
      _loading = null;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    if (_userKey == null) return;
    await _load();
  }

  Future<Map<String, dynamic>?> toggleMenu(String slug, String codigo) async {
    if (_userKey == null) return null;

    final wasLiked = _menus.contains(codigo);
    _menus = Set<String>.from(_menus);
    if (wasLiked) {
      _menus.remove(codigo);
    } else {
      _menus.add(codigo);
    }
    notifyListeners();

    try {
      final data = await InteraccionService.toggleEncanta(slug);
      final serverLiked = data?['meEncanta'] as bool?;
      if (serverLiked != null) {
        _menus = Set<String>.from(_menus);
        if (serverLiked) {
          _menus.add(codigo);
        } else {
          _menus.remove(codigo);
        }
        notifyListeners();
      }
      return data;
    } catch (_) {
      _menus = Set<String>.from(_menus);
      if (wasLiked) {
        _menus.add(codigo);
      } else {
        _menus.remove(codigo);
      }
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> toggleProducto(
    String slug,
    String codigo,
  ) async {
    if (_userKey == null) return null;

    final wasLiked = _productos.contains(codigo);
    _productos = Set<String>.from(_productos);
    if (wasLiked) {
      _productos.remove(codigo);
    } else {
      _productos.add(codigo);
    }
    notifyListeners();

    try {
      final data = await InteraccionService.toggleEncantaProducto(slug, codigo);
      final serverLiked = data?['meEncanta'] as bool?;
      if (serverLiked != null) {
        _productos = Set<String>.from(_productos);
        if (serverLiked) {
          _productos.add(codigo);
        } else {
          _productos.remove(codigo);
        }
        notifyListeners();
      }
      return data;
    } catch (_) {
      _productos = Set<String>.from(_productos);
      if (wasLiked) {
        _productos.add(codigo);
      } else {
        _productos.remove(codigo);
      }
      notifyListeners();
      return null;
    }
  }
}
