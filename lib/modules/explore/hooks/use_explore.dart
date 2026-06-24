import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../services/app_cache.dart';
import '../../../services/explore_service.dart';
import '../../../services/public_api_service.dart';
import '../../../services/interaccion_service.dart';
import '../../../hooks/use_geo_location.dart';
import '../../menu/public/models/public_menu_model.dart';

// Equivalente a src/modules/explore/hooks/useExplore.js en React

class ExploreController extends ChangeNotifier with WidgetsBindingObserver {
  // Constructor: precarga la caché de manera síncrona (sin await).
  // Así didChangeDependencies() en ExplorePage ya ve el estado correcto
  // y el splash nunca aparece si hay datos cacheados.
  ExploreController() {
    // Usar datos aunque estén stale (caídas de internet) — mejor mostrar
    // datos viejos que una pantalla vacía
    final cached = AppCache.get('explore_feed_latest')
                ?? AppCache.getStale('explore_feed_latest');
    if (cached != null) {
      _feed        = ExploreFeed.fromJson(cached as Map<String, dynamic>);
      _feedLoading = false;
    }
  }

  // ── Búsqueda ────────────────────────────────────────────────────────────────
  String                _search         = '';
  List<MenuFeedItem>?   _searchResults;
  bool                  _searchLoading  = false;
  Timer?                _searchTimer;

  // ── Feed ────────────────────────────────────────────────────────────────────
  ExploreFeed?  _feed;
  bool          _feedLoading             = true;   // constructor lo sobreescribe si hay caché
  int           _feedVersion             = 0;
  int           _offlineRecoveredVersion = 0;
  bool          _bannerDismissed         = false;

  // ── Likes ────────────────────────────────────────────────────────────────────
  Set<int>  _likedIds = {};

  // ── Ubicación ────────────────────────────────────────────────────────────────
  String?   _ciudad;

  // ── Conectividad ─────────────────────────────────────────────────────────────
  bool _noInternet = false;

  // ── Auth (lo recibe desde fuera) ─────────────────────────────────────────────
  bool _isLoggedIn    = false;
  bool _initialized   = false;

  // ── Getters ──────────────────────────────────────────────────────────────────
  String              get search                   => _search;
  List<MenuFeedItem>? get searchResults            => _searchResults;
  bool                get searchLoading            => _searchLoading;
  bool                get feedLoading              => _feedLoading;
  ExploreFeed?        get feed                     => _feed;
  int                 get feedVersion              => _feedVersion;
  int                 get offlineRecoveredVersion  => _offlineRecoveredVersion;
  Set<int>            get likedIds                 => _likedIds;
  String?             get ciudad                   => _ciudad;
  bool                get showingSearch            => _search.trim().isNotEmpty;
  bool                get noInternet               => _noInternet;
  // True solo si el feed tiene contenido real (no el fallback vacío)
  bool get hasFeedData =>
      _feed != null &&
      (_feed!.nearby.isNotEmpty || _feed!.trending.isNotEmpty || _feed!.nuevo.isNotEmpty);

  bool _showLocBanner = false;
  bool get locBanner  => _showLocBanner;

  // ── Dedup (igual que useExplore.js) ─────────────────────────────────────────
  ({ExploreFeed dedupedFeed, Set<int> excludeIds}) get deduped {
    if (_feed == null) {
      return (dedupedFeed: ExploreFeed.empty, excludeIds: const {});
    }
    final seen = <int>{};
    List<MenuFeedItem> filter(List<MenuFeedItem> list) => list.where((m) {
      if (m.menId == 0 || seen.contains(m.menId)) return false;
      seen.add(m.menId);
      return true;
    }).toList();

    return (
      dedupedFeed: ExploreFeed(
        nearby:   filter(_feed!.nearby),
        trending: filter(_feed!.trending),
        nuevo:    filter(_feed!.nuevo),
      ),
      excludeIds: Set.of(seen),
    );
  }

  // ── Init (idempotente: solo corre completo la primera vez) ───────────────────
  Future<void> init({bool isLoggedIn = false}) async {
    _isLoggedIn = isLoggedIn;
    WidgetsBinding.instance.addObserver(this);

    if (_initialized) {
      // Ya inicializado: actualizar likes si hace falta y salir
      if (isLoggedIn && _likedIds.isEmpty) {
        final ids = await InteraccionService.misEncantados();
        _likedIds = ids.toSet();
        notifyListeners();
      }
      return;
    }
    _initialized = true;

    // Leer ciudad guardada
    final loc = await getStoredLocation();
    _ciudad = loc?['ciudad'] as String?;

    // Stale-while-revalidate: mostrar caché inmediatamente si existe
    final cacheKey = 'explore_feed_${_ciudad ?? ''}';
    final cached = AppCache.get(cacheKey);
    if (cached != null) {
      _feed        = ExploreFeed.fromJson(cached as Map<String, dynamic>);
      _feedLoading = false;
      notifyListeners();
    }

    // Banner de ubicación
    if (isLoggedIn) {
      final geoStatus = await getStoredGeoStatus();
      _showLocBanner = geoStatus == null && !_bannerDismissed;
      notifyListeners();
    }

    // Fetch inicial en background (revalida aunque haya caché)
    await loadFeed(_ciudad);

    // Likes del usuario (solo si logueado)
    if (isLoggedIn) {
      final ids = await InteraccionService.misEncantados();
      _likedIds = ids.toSet();
      notifyListeners();
    }
  }

  // ── Firma del feed para detectar cambios reales ───────────────────────────────
  String _sig(ExploreFeed f) {
    final ids = [...f.nearby, ...f.trending, ...f.nuevo]
        .map((m) => m.menId)
        .toList()
      ..sort();
    return ids.join(',');
  }

  bool _feedChanged(ExploreFeed newFeed) =>
      _feed == null || _sig(_feed!) != _sig(newFeed);

  // ── Cargar feed ───────────────────────────────────────────────────────────────
  Future<void> loadFeed([String? ciudad]) async {
    final target     = ciudad ?? _ciudad;
    final wasOffline = _noInternet;
    _noInternet = false;
    // Solo mostrar spinner si no hay datos aún (primera carga sin caché)
    if (_feed == null) {
      _feedLoading = true;
      notifyListeners();
    }
    try {
      final data    = await ExploreService.getFeed(ciudad: target);
      final newFeed = ExploreFeed.fromJson(data);
      // Si recuperamos internet, limpiar imágenes fallidas del caché de Flutter
      if (wasOffline) {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        _offlineRecoveredVersion++;
      }
      AppCache.set('explore_feed_${target ?? ''}', data);
      AppCache.set('explore_feed_latest', data);
      // Solo redibujar InfiniteExplorer si los datos realmente cambiaron
      if (_feedChanged(newFeed) || wasOffline) _feedVersion++;
      _feed = newFeed;
    } catch (e) {
      final msg = e.toString();
      final isNetErr = e is SocketException
          || e is http.ClientException
          || msg.contains('SocketException')
          || msg.contains('ClientException')
          || msg.contains('Failed host lookup')
          || msg.contains('Network is unreachable')
          || msg.contains('Connection refused')
          || msg.contains('Connection reset')
          || msg.contains('TimeoutException');
      if (isNetErr) _noInternet = true;
      AppCache.markStale('explore_feed_${target ?? ''}');
      _feed ??= ExploreFeed.empty;
    }
    _feedLoading = false;
    notifyListeners();
  }

  // ── Refresh silencioso al volver al Explorer (sin spinner, sin rebuild si no hay cambios) ─
  Future<void> silentRefresh() async {
    try {
      final data    = await ExploreService.getFeed(ciudad: _ciudad);
      final newFeed = ExploreFeed.fromJson(data);
      AppCache.set('explore_feed_${_ciudad ?? ''}', data);
      AppCache.set('explore_feed_latest', data);
      if (_feedChanged(newFeed)) {
        _feed = newFeed;
        _feedVersion++;
        notifyListeners();
      }
    } catch (_) {
      // Silencioso: si falla, no tocamos nada
    }
  }

  // ── Refetch en background al volver al primer plano (equiv. window focus) ─────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      silentRefresh();
    }
  }

  // ── Búsqueda (debounce 350ms igual que React) ─────────────────────────────────
  void setSearch(String value) {
    _search        = value;
    _searchTimer?.cancel();

    if (value.trim().isEmpty) {
      _searchResults = null;
      _searchLoading = false;
      notifyListeners();
      return;
    }

    // Activar spinner de inmediato — evita que aparezca "Sin resultados" durante el debounce
    _searchLoading = true;
    notifyListeners();
    _searchTimer = Timer(const Duration(milliseconds: 350), () => _doSearch(value.trim()));
  }

  Future<void> _doSearch(String q) async {
    _searchLoading = true;
    notifyListeners();
    final results = await PublicApiService.buscarMenus(q);
    _searchResults = results
        .whereType<Map<String, dynamic>>()
        .map(MenuFeedItem.fromJson)
        .toList();
    _searchLoading = false;
    notifyListeners();
  }

  void clearSearch() => setSearch('');

  // ── Ubicación ─────────────────────────────────────────────────────────────────
  Future<void> handleLocationGranted(double lat, double lon) async {
    _showLocBanner  = false;
    _bannerDismissed = true;

    // Reverse geocode con Nominatim (igual que useExplore.js)
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=es',
      );
      final res = await _nominatimGet(uri);
      if (res != null) {
        final addr = res['address'] as Map<String, dynamic>? ?? {};
        final c = addr['city'] as String?
            ?? addr['town'] as String?
            ?? addr['municipality'] as String?
            ?? addr['county'] as String?;
        await storeLocation(lat, lon, c);
        if (c != null && c != _ciudad) {
          _ciudad = c;
          _feedLoading = true;
          notifyListeners();
          await loadFeed(c);
        }
        if (_isLoggedIn) ExploreService.saveLocation(lat, lon, c);
      } else {
        await storeLocation(lat, lon, null);
        if (_isLoggedIn) ExploreService.saveLocation(lat, lon, null);
      }
    } catch (_) {
      await storeLocation(lat, lon, null);
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _nominatimGet(Uri uri) async {
    try {
      final res = await http.get(uri, headers: {
        'User-Agent': 'Zammpy/1.0',
      }).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void handleDismissLocation() {
    _showLocBanner  = false;
    _bannerDismissed = true;
    setGeoStatus('denied');
    notifyListeners();
  }

  // ── Likes: recargar tras login / limpiar tras logout ─────────────────────────
  Future<void> reloadLikes() async {
    final ids = await InteraccionService.misEncantados();
    _likedIds = ids.toSet();
    notifyListeners();
  }

  void clearLikes() {
    _likedIds = {};
    notifyListeners();
  }

  // ── Toggle like (optimista igual que React) ───────────────────────────────────
  Future<void> toggleLike(MenuFeedItem item, bool isLoggedIn) async {
    if (!isLoggedIn) return;

    final wasLiked = _likedIds.contains(item.menId);
    // Optimistic update
    if (wasLiked) {
      _likedIds = Set.from(_likedIds)..remove(item.menId);
    } else {
      _likedIds = Set.from(_likedIds)..add(item.menId);
    }
    notifyListeners();

    try {
      final data = await InteraccionService.toggleEncanta(item.slug);
      if (data != null) {
        final serverLiked = data['meEncanta'] as bool? ?? !wasLiked;
        if (serverLiked) {
          _likedIds = Set.from(_likedIds)..add(item.menId);
        } else {
          _likedIds = Set.from(_likedIds)..remove(item.menId);
        }
        notifyListeners();
      }
    } catch (_) {
      // Revertir
      if (wasLiked) {
        _likedIds = Set.from(_likedIds)..add(item.menId);
      } else {
        _likedIds = Set.from(_likedIds)..remove(item.menId);
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchTimer?.cancel();
    super.dispose();
  }
}
