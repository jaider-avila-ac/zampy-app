import 'dart:async';

import 'package:flutter/material.dart';

import '../modules/orders/utils/order_items.dart';
import '../services/carrito_service.dart';

// Equivalente a src/context/CartContext.jsx en React.
// Un carrito por menú, guardado en el servidor con 1 s de espera tras cada cambio.

class CartContext extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  String? _menuCodigo;
  String? _menuSlug;
  String _whatsapp = '';
  String _menuNombre = '';
  Timer? _saveTimer;
  int _carga = 0; // descarta respuestas de un menú anterior

  List<Map<String, dynamic>> get items => _items;
  String? get menuCodigo => _menuCodigo;
  String? get menuSlug => _menuSlug;
  String get whatsapp => _whatsapp;
  String get menuNombre => _menuNombre;
  num get total => calculateOrderTotal(_items);
  int get count => _items.fold<int>(0, (n, i) => n + ((i['quantity'] as num?)?.toInt() ?? 0));

  /// Al entrar a un menú: lo fija y carga el carrito guardado de ese menú.
  Future<void> initMenu(String codigo, String? slug, String? whatsapp, String? nombre) async {
    if (_menuCodigo == codigo) return;
    _saveTimer?.cancel();
    _menuCodigo = codigo;
    _menuSlug = slug;
    _whatsapp = whatsapp ?? '';
    _menuNombre = nombre ?? '';
    _items = [];
    notifyListeners();
    final carga = ++_carga;
    final guardados = await CarritoService.get(codigo);
    if (carga != _carga || _menuCodigo != codigo) return;
    if (guardados.isNotEmpty) {
      _items = guardados;
      notifyListeners();
    }
  }

  void _cambiar(List<Map<String, dynamic>> nuevos) {
    _items = nuevos;
    notifyListeners();
    final codigo = _menuCodigo;
    if (codigo == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () => CarritoService.save(codigo, _items));
  }

  void addItem(Map<String, dynamic> item) => _cambiar(addConfiguredOrderItem(_items, item));

  void removeItem(String key) =>
      _cambiar(_items.where((i) => buildOrderItemKey(i) != key).toList());

  void updateQuantity(String key, int delta) => _cambiar([
        for (final i in _items)
          if (buildOrderItemKey(i) != key)
            i
          else if (((i['quantity'] as num?) ?? 0) + delta > 0)
            {...i, 'quantity': ((i['quantity'] as num?) ?? 0) + delta},
      ]);

  /// Vacía el carrito y lo borra también en el servidor.
  void clearCart() {
    _saveTimer?.cancel();
    _items = [];
    notifyListeners();
    final codigo = _menuCodigo;
    if (codigo != null) CarritoService.clear(codigo);
  }

  /// Al cerrar sesión: el carrito es de la cuenta, no del dispositivo.
  void reset() {
    _saveTimer?.cancel();
    _carga++;
    _items = [];
    _menuCodigo = null;
    _menuSlug = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
