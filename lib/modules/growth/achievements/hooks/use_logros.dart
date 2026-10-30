import 'package:flutter/material.dart';
import '../../../../services/app_cache.dart';
import '../../../../services/logro_service.dart';
import '../../../../services/mis_menus_service.dart';
import '../../../explore/models/explore_models.dart';
import '../models/logro_model.dart';

// Equivalente a src/modules/growth/achievements/hooks/useLogros.js + la lógica de aplicar de LogrosPage.jsx

const _cacheKey = 'logros';

String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

class UseLogros extends ChangeNotifier {
  List<LogroModel> _logros  = [];
  bool             _loading = true;
  bool             _error   = false;
  bool             _disposed = false;

  // Aplicar recompensas
  List<TarjetaMenu> _menus = [];
  String?           _menuCodigo;
  final Set<String> _selected = {};
  bool              _applying = false;
  String            _actionError = '';
  String            _success = '';
  // Se reutiliza el requestId mientras no cambie la operación: un reintento tras
  // un fallo de red no aplica los días dos veces.
  String _operationKey = '';
  String _requestId = '';

  List<LogroModel> get logros        => _logros;
  bool             get loading       => _loading;
  bool             get error         => _error;
  List<LogroModel> get desbloqueados => _logros.where((l) =>  l.desbloqueado).toList();
  List<LogroModel> get pendientes    => _logros.where((l) => !l.desbloqueado).toList();
  List<LogroModel> get disponibles   => desbloqueados.where((l) => l.disponible).toList();

  List<TarjetaMenu> get menus       => _menus;
  String?           get menuCodigo  => _menuCodigo;
  Set<String>       get selected    => _selected;
  bool              get applying    => _applying;
  String            get actionError => _actionError;
  String            get success     => _success;
  bool get puedeAplicar => _menuCodigo != null && _selected.isNotEmpty && !_applying;

  /// Nombre del menú propio con ese código (para "Aplicado · Mi menú").
  String? nombreMenu(String? codigo) {
    if (codigo == null) return null;
    for (final m in _menus) {
      if (m.codigo == codigo) return m.nombre.isNotEmpty ? m.nombre : m.slug;
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    // Stale-while-revalidate: mostrar caché inmediatamente
    final cached = AppCache.get(_cacheKey);
    if (cached is List) {
      _logros  = cached.whereType<Map>()
          .map((e) => LogroModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _loading = false;
    }
    _error = false;
    _notify();
    await Future.wait([_loadLogros(), _loadMenus()]);
  }

  Future<void> _loadLogros() async {
    try {
      final raw = await LogroService.miProgreso();
      AppCache.set(_cacheKey, raw);
      _logros = raw.map(LogroModel.fromJson).toList();
      _error = false;
    } catch (_) {
      AppCache.markStale(_cacheKey);
      // Con datos en caché se siguen mostrando; sin ellos se ofrece reintentar.
      _error = _logros.isEmpty;
    }
    _loading = false;
    _notify();
  }

  // Solo los menús propios: "Mis menús" no incluye las colaboraciones.
  Future<void> _loadMenus() async {
    try {
      final data = await MisMenusService.getTarjetas();
      _menus = data.items;
      if (_menus.length == 1) _menuCodigo = _menus.first.codigo;
    } catch (_) {
      _actionError = 'No se pudieron cargar tus menús.';
    }
    _notify();
  }

  Future<void> refetch() async {
    _loading = _logros.isEmpty;
    _error = false;
    _notify();
    await _loadLogros();
  }

  void setMenu(String? codigo) {
    _menuCodigo = codigo;
    _notify();
  }

  void toggleSelected(String codigo) {
    if (!_selected.remove(codigo)) _selected.add(codigo);
    _notify();
  }

  Future<void> aplicar() async {
    final menu = _menuCodigo;
    if (menu == null || _selected.isEmpty || _applying) return;
    final ordenados = [..._selected]..sort();
    final key = '$menu:${ordenados.join(',')}';
    if (_operationKey != key) {
      _operationKey = key;
      _requestId = LogroService.nuevoRequestId();
    }
    _applying = true;
    _actionError = '';
    _success = '';
    _notify();
    try {
      final r = await LogroService.aplicar(menu, ordenados, _requestId);
      final dias = (r['diasAplicados'] as num?)?.toInt() ?? 0;
      _success = '$dias días aplicados correctamente.';
      _operationKey = '';
      _requestId = '';
      _selected.clear();
      await _loadLogros();
    } catch (e) {
      final m = _msg(e);
      _actionError = m.isEmpty ? 'No se pudieron aplicar los días.' : m;
    } finally {
      _applying = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
