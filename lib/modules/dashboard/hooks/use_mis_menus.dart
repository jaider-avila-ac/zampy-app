import 'package:flutter/material.dart';

import '../../../services/app_cache.dart';
import '../../../services/mis_menus_service.dart';
import '../../explore/models/explore_models.dart';
import '../models/dashboard_models.dart';

// Equivalente a src/modules/dashboard/hooks/useMisMenus.js en React.
// Tarjetas propias + colaboraciones, ambas con código público.

class UseMisMenus extends ChangeNotifier {
  List<TarjetaMenu> _menus = [];
  List<ColaboracionMenu> _colaborados = [];
  int? _limiteMenus;
  bool _loading = true;
  bool _loadingColab = true;
  String? _errorMenus;
  String? _errorColab;

  List<TarjetaMenu> get menus => _menus;
  List<ColaboracionMenu> get colaborados => _colaborados;
  int? get limiteMenus => _limiteMenus;
  bool get loading => _loading;
  bool get loadingColab => _loadingColab;
  String? get errorMenus => _errorMenus;
  String? get errorColab => _errorColab;

  bool get atLimit {
    final lim = _limiteMenus;
    return lim != null && _menus.length >= lim;
  }

  Future<void> load() async {
    final cachedMenus = AppCache.get('mis_menus');
    final cachedColab = AppCache.get('mis_colaboraciones');
    if (cachedMenus is MisMenusData) {
      _applyMenus(cachedMenus);
      _loading = false;
    }
    if (cachedColab is List) {
      _colaborados = cachedColab.whereType<ColaboracionMenu>().toList();
      _loadingColab = false;
    }
    if (cachedMenus != null || cachedColab != null) notifyListeners();

    await Future.wait([_fetchMenus(), _fetchColaboraciones()]);
  }

  Future<void> reload() async {
    _loading = true;
    _loadingColab = true;
    _errorMenus = null;
    _errorColab = null;
    notifyListeners();
    await Future.wait([_fetchMenus(), _fetchColaboraciones()]);
  }

  Future<void> retryMenus() async {
    _loading = true;
    _errorMenus = null;
    notifyListeners();
    await _fetchMenus();
  }

  Future<void> retryColaboraciones() async {
    _loadingColab = true;
    _errorColab = null;
    notifyListeners();
    await _fetchColaboraciones();
  }

  Future<void> _fetchMenus() async {
    try {
      final data = await MisMenusService.getTarjetas();
      _applyMenus(data);
      _errorMenus = null;
      AppCache.set('mis_menus', data);
    } catch (e) {
      AppCache.markStale('mis_menus');
      if (_menus.isEmpty) _errorMenus = _cleanError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _fetchColaboraciones() async {
    try {
      final data = await MisMenusService.getColaboraciones();
      _colaborados = data;
      _errorColab = null;
      AppCache.set('mis_colaboraciones', data);
    } catch (e) {
      AppCache.markStale('mis_colaboraciones');
      if (_colaborados.isEmpty) _errorColab = _cleanError(e);
    }
    _loadingColab = false;
    notifyListeners();
  }

  void _applyMenus(MisMenusData data) {
    _menus = data.items;
    _limiteMenus = data.limiteMenus;
  }

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
}
