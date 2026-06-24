import 'package:flutter/material.dart';
import '../../../services/app_cache.dart';
import '../../../services/mis_menus_service.dart';

// Equivalente a src/modules/dashboard/hooks/useMisMenus.js en React
// Sin lógica de delete (se implementará después)

class UseMisMenus extends ChangeNotifier {
  List<dynamic> _menus        = [];
  List<dynamic> _colaborados  = [];
  bool          _loading      = true;
  bool          _loadingColab = true;
  int?          _openMenuId;

  List<dynamic> get menus        => _menus;
  List<dynamic> get colaborados  => _colaborados;
  bool          get loading      => _loading;
  bool          get loadingColab => _loadingColab;
  int?          get openMenuId   => _openMenuId;

  // limiteMenus viene del primer menú (igual que React)
  int? get limiteMenus {
    if (_menus.isEmpty) return null;
    final sub = (_menus[0] as Map<String, dynamic>)['subscription'];
    if (sub == null) return null;
    return (sub as Map<String, dynamic>)['limiteMenus'] as int?;
  }

  bool get atLimit {
    final lim = limiteMenus;
    return lim != null && _menus.length >= lim;
  }

  Future<void> load() async {
    // Stale-while-revalidate: mostrar caché inmediatamente
    final cachedMenus = AppCache.get('mis_menus');
    final cachedColab = AppCache.get('mis_colaboraciones');
    if (cachedMenus != null) {
      _menus   = _sorted(cachedMenus as List);
      _loading = false;
    }
    if (cachedColab != null) {
      _colaborados  = cachedColab as List;
      _loadingColab = false;
    }
    if (cachedMenus != null || cachedColab != null) notifyListeners();

    // Fetch en paralelo
    await Future.wait([_fetchMenus(), _fetchColaboraciones()]);
  }

  Future<void> reload() async {
    _loading      = true;
    _loadingColab = true;
    notifyListeners();
    await Future.wait([_fetchMenus(), _fetchColaboraciones()]);
  }

  Future<void> _fetchMenus() async {
    try {
      final data = await MisMenusService.getAll();
      final sorted = _sorted(data);
      AppCache.set('mis_menus', data);
      _menus = sorted;
    } catch (_) {
      AppCache.markStale('mis_menus');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _fetchColaboraciones() async {
    try {
      final data = await MisMenusService.misColaboraciones();
      AppCache.set('mis_colaboraciones', data);
      _colaborados = data;
    } catch (_) {
      AppCache.markStale('mis_colaboraciones');
    }
    _loadingColab = false;
    notifyListeners();
  }

  // Ordena por createdAt descendente (igual que useMemo en React)
  List<dynamic> _sorted(List<dynamic> raw) {
    final list = List<dynamic>.from(raw);
    list.sort((a, b) {
      final da = DateTime.tryParse((a as Map)['createdAt'] as String? ?? '') ?? DateTime(0);
      final db = DateTime.tryParse((b as Map)['createdAt'] as String? ?? '') ?? DateTime(0);
      return db.compareTo(da);
    });
    return list;
  }

  void toggleDropdown(int menuId) {
    _openMenuId = _openMenuId == menuId ? null : menuId;
    notifyListeners();
  }

  void closeDropdown() {
    _openMenuId = null;
    notifyListeners();
  }
}
