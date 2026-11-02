import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../services/api_client.dart';
import '../../../services/explore_service.dart';
import '../../../services/public_api_service.dart';
import '../models/explore_models.dart';

// Equivalente a src/modules/explore/hooks/useExplore.js en React

class ExploreController extends ChangeNotifier with WidgetsBindingObserver {
  String _vista = 'menus';
  ExploreFiltros? _filtros;
  bool _filtrosLoading = true;
  String? _filtrosError;

  String? _municipioMenus;
  String? _categoriaMenus;
  String? _municipioPlatos;
  String? _categoriaPlatos;

  String _search = '';
  List<TarjetaMenu>? _searchResults;
  bool _searchLoading = false;
  Timer? _searchTimer;
  int _searchSeq = 0;

  String _busquedaPlatos = '';
  String _qPlatos = '';
  Timer? _platosTimer;

  final List<TarjetaMenu> _menus = [];
  String? _menuCursor;
  bool _menuHasMore = true;
  bool _menuLoading = false;
  String? _menusError;
  int _menuSeq = 0;

  final List<TarjetaProducto> _productos = [];
  String? _productoCursor;
  bool _productoHasMore = true;
  bool _productoLoading = false;
  String? _productosError;
  bool _productosIniciados = false;
  int _productoSeq = 0;

  bool _initialized = false;
  bool _noInternet = false;
  bool _platosAbierto = false;

  final String _semilla = _generarSemilla();

  String get vista => _vista;
  ExploreFiltros? get filtros => _filtros;
  bool get filtrosLoading => _filtrosLoading;
  String? get filtrosError => _filtrosError;

  String? get municipioMenus => _municipioMenus;
  String? get categoriaMenus => _categoriaMenus;
  String? get municipioPlatos => _municipioPlatos;
  String? get categoriaPlatos => _categoriaPlatos;

  String get search => _search;
  List<TarjetaMenu>? get searchResults => _searchResults;
  bool get searchLoading => _searchLoading;
  bool get showingSearch => _search.trim().isNotEmpty;

  String get busquedaPlatos => _busquedaPlatos;
  String get qPlatos => _qPlatos;

  List<TarjetaMenu> get menus => List.unmodifiable(_menus);
  bool get menuLoading => _menuLoading;
  bool get menuHasMore => _menuHasMore;
  String? get menusError => _menusError;

  List<TarjetaProducto> get productos => List.unmodifiable(_productos);
  bool get productoLoading => _productoLoading;
  bool get productoHasMore => _productoHasMore;
  String? get productosError => _productosError;

  bool get platosAbierto => _platosAbierto;
  bool get noInternet => _noInternet;
  bool get initialLoading =>
      _filtrosLoading || (_menuLoading && _menus.isEmpty);
  bool get hasAnyData =>
      _menus.isNotEmpty ||
      _productos.isNotEmpty ||
      (_searchResults?.isNotEmpty ?? false);

  Future<void> init({bool isLoggedIn = false}) async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);

    // Como React (useExplore.js): el lugar por defecto es siempre "todos los lugares" (null).
    // No se restaura de almacenamiento ni se autollena con el municipio del perfil.
    await cargarFiltros();
    await loadMenus(reset: true);
  }

  Future<void> onAuthChanged({required bool isLoggedIn}) async {
    if (!isLoggedIn) {
      // Al cerrar sesión se olvida el lugar (React limpia localStorage en logout).
      if (_municipioMenus == null && _municipioPlatos == null) return;
      _municipioMenus = null;
      _municipioPlatos = null;
      if (_initialized) {
        await loadMenus(reset: true);
        if (_vista == 'platos') await loadProductos(reset: true);
      }
      return;
    }
    // Al iniciar sesión no se autoselecciona ningún lugar: sigue en "todos los lugares" (como React).
  }

  Future<void> cargarFiltros() async {
    _filtrosLoading = true;
    _filtrosError = null;
    notifyListeners();
    try {
      final filtros = await ExploreService.getFiltros();
      _filtros = filtros;
      _municipioMenus = _validarMunicipio(_municipioMenus, filtros);
      _municipioPlatos = _validarMunicipio(_municipioPlatos, filtros);
    } catch (_) {
      _filtros = ExploreFiltros.empty;
      _filtrosError = 'No se pudieron cargar los filtros.';
      _noInternet = true;
    } finally {
      _filtrosLoading = false;
      notifyListeners();
    }
  }

  String? _validarMunicipio(String? codigo, ExploreFiltros filtros) {
    if (codigo == null || codigo.isEmpty) return null;
    return filtros.lugares.any((l) => l.codigo == codigo) ? codigo : null;
  }


  Future<void> loadMenus({bool reset = false}) async {
    if (!reset && (_menuLoading || !_menuHasMore)) return;
    if (reset) {
      _menuSeq++;
      _menus.clear();
      _menuCursor = null;
      _menuHasMore = true;
      _menusError = null;
    }
    final seq = _menuSeq;
    _menuLoading = true;
    notifyListeners();

    try {
      final page = await ExploreService.getScroll(
        cursor: reset ? null : _menuCursor,
        municipio: _municipioMenus,
        categoria: _categoriaMenus,
      );
      if (seq != _menuSeq) return;
      final vistos = _menus.map((m) => m.codigo).toSet();
      final nuevos = page.items
          .where((m) => m.codigo.isNotEmpty && !vistos.contains(m.codigo))
          .toList();
      _menus.addAll(nuevos);
      _menuCursor = page.nextCursor;
      _menuHasMore = page.hasMore && page.nextCursor != null;
      _menusError = null;
      _noInternet = false;
    } catch (e) {
      if (seq != _menuSeq) return;
      _menusError = _errorMessage(e, 'No se pudieron cargar los menús.');
      _noInternet = _isNetworkError(e);
      if (reset) _menus.clear();
      _menuHasMore = false;
    } finally {
      if (seq == _menuSeq) {
        _menuLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreMenus() => loadMenus();

  Future<void> loadProductos({bool reset = false}) async {
    if (!reset && (_productoLoading || !_productoHasMore)) return;
    _productosIniciados = true;
    _platosAbierto = true;
    if (reset) {
      _productoSeq++;
      _productos.clear();
      _productoCursor = null;
      _productoHasMore = true;
      _productosError = null;
    }
    final seq = _productoSeq;
    _productoLoading = true;
    notifyListeners();

    try {
      final page = await ExploreService.getProductos(
        municipio: _municipioPlatos,
        categoria: _categoriaPlatos,
        q: _qPlatos,
        semilla: _semilla,
        despues: reset ? null : _productoCursor,
      );
      if (seq != _productoSeq) return;
      final vistos = _productos.map((p) => '${p.menuSlug}-${p.codigo}').toSet();
      // Explore es para ver los platos: los que no tienen foto no se muestran (igual que en la web)
      final nuevos = page.items
          .where(
            (p) =>
                p.codigo.isNotEmpty &&
                p.imagenUrl != null &&
                p.imagenUrl!.isNotEmpty &&
                !vistos.contains('${p.menuSlug}-${p.codigo}'),
          )
          .toList();
      _productos.addAll(nuevos);
      _productoCursor = page.siguiente;
      _productoHasMore = page.siguiente != null;
      _productosError = null;
      _noInternet = false;
    } catch (e) {
      if (seq != _productoSeq) return;
      _productosError = _errorMessage(e, 'No se pudieron cargar los platos.');
      _noInternet = _isNetworkError(e);
      if (reset) _productos.clear();
      _productoHasMore = false;
    } finally {
      if (seq == _productoSeq) {
        _productoLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreProductos() => loadProductos();

  void loadMoreActive() {
    if (_vista == 'menus') {
      if (showingSearch) return;
      loadMoreMenus();
    } else {
      loadMoreProductos();
    }
  }

  void setVista(String vista) {
    if (vista == _vista) return;
    _vista = vista;
    if (vista == 'platos') {
      _platosAbierto = true;
      if (!_productosIniciados) {
        loadProductos(reset: true);
      }
    }
    notifyListeners();
  }

  void cambiarMunicipioMenus(String? codigo) {
    _municipioMenus = codigo;
    _searchTimer?.cancel();
    loadMenus(reset: true);
    if (showingSearch) _doSearch();
  }

  void cambiarCategoriaMenus(String? codigo) {
    _categoriaMenus = codigo;
    _searchTimer?.cancel();
    loadMenus(reset: true);
    if (showingSearch) _doSearch();
  }

  void cambiarMunicipioPlatos(String? codigo) {
    _municipioPlatos = codigo;
    loadProductos(reset: true);
  }

  void cambiarCategoriaPlatos(String? codigo) {
    _categoriaPlatos = codigo;
    loadProductos(reset: true);
  }

  void setSearch(String value) {
    _search = value;
    _searchTimer?.cancel();

    if (value.trim().isEmpty) {
      _searchSeq++;
      _searchResults = null;
      _searchLoading = false;
      notifyListeners();
      return;
    }

    _searchSeq++;
    _searchLoading = true;
    notifyListeners();
    _searchTimer = Timer(const Duration(milliseconds: 350), _doSearch);
  }

  Future<void> _doSearch() async {
    final q = _search.trim();
    if (q.isEmpty) return;
    final seq = ++_searchSeq;
    _searchLoading = true;
    notifyListeners();
    try {
      final results = await PublicApiService.buscarMenus(
        search: q,
        categoria: _categoriaMenus ?? '',
        municipio: _municipioMenus ?? '',
      );
      if (seq != _searchSeq) return;
      _searchResults = results;
      _searchLoading = false;
      notifyListeners();
    } catch (_) {
      if (seq != _searchSeq) return;
      _searchResults = [];
      _searchLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() => setSearch('');

  void setBusquedaPlatos(String value) {
    _busquedaPlatos = value;
    _platosTimer?.cancel();
    _platosTimer = Timer(const Duration(milliseconds: 350), () {
      _qPlatos = _busquedaPlatos.trim();
      if (_platosAbierto || _vista == 'platos') {
        loadProductos(reset: true);
      } else {
        notifyListeners();
      }
    });
    notifyListeners();
  }

  Future<void> refresh() async {
    await cargarFiltros();
    if (_vista == 'menus') {
      await loadMenus(reset: true);
      if (showingSearch) await _doSearch();
    } else {
      await loadProductos(reset: true);
    }
  }

  Future<void> silentRefresh() async {
    try {
      if (_vista == 'menus') {
        await loadMenus(reset: true);
      } else {
        await loadProductos(reset: true);
      }
    } catch (_) {}
  }

  bool _isNetworkError(Object error) {
    if (error is ApiException) {
      return error.message.toLowerCase().contains('conectar') ||
          error.message.toLowerCase().contains('conexión');
    }
    return false;
  }

  String _errorMessage(Object error, String fallback) {
    if (error is ApiException && error.message.isNotEmpty) {
      return error.message;
    }
    return fallback;
  }

  static String _generarSemilla() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_';
    final random = Random.secure();
    return List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) silentRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchTimer?.cancel();
    _platosTimer?.cancel();
    super.dispose();
  }
}
