import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../services/explore_service.dart';
import '../../../services/public_api_service.dart';
import '../../../services/interaccion_service.dart';
import '../../../hooks/use_geo_location.dart';
import '../../menu/public/models/public_menu_model.dart';

// Equivalente a src/modules/explore/hooks/useExplore.js en React

class ExploreController extends ChangeNotifier {
  // ── Búsqueda ────────────────────────────────────────────────────────────────
  String                _search         = '';
  List<MenuFeedItem>?   _searchResults;
  bool                  _searchLoading  = false;
  Timer?                _searchTimer;

  // ── Feed ────────────────────────────────────────────────────────────────────
  ExploreFeed?  _feed;
  bool          _feedLoading     = true;
  int           _feedVersion     = 0;
  bool          _bannerDismissed = false;

  // ── Likes ────────────────────────────────────────────────────────────────────
  Set<int>  _likedIds = {};

  // ── Ubicación ────────────────────────────────────────────────────────────────
  String?   _ciudad;

  // ── Auth (lo recibe desde fuera) ─────────────────────────────────────────────
  bool _isLoggedIn = false;

  // ── Getters ──────────────────────────────────────────────────────────────────
  String              get search        => _search;
  List<MenuFeedItem>? get searchResults => _searchResults;
  bool                get searchLoading => _searchLoading;
  bool                get feedLoading   => _feedLoading;
  ExploreFeed?        get feed          => _feed;
  int                 get feedVersion   => _feedVersion;
  Set<int>            get likedIds      => _likedIds;
  String?             get ciudad        => _ciudad;
  bool                get showingSearch => _search.trim().isNotEmpty;

  bool get showLocBanner {
    // Igual que en useExplore.js: solo si logueado y no hay geo status y no descartado
    return false; // La lógica completa se activa en init()
  }

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

  // ── Init ─────────────────────────────────────────────────────────────────────
  Future<void> init({bool isLoggedIn = false}) async {
    _isLoggedIn = isLoggedIn;

    // Leer ciudad guardada
    final loc = await getStoredLocation();
    _ciudad = loc?['ciudad'] as String?;

    // Verificar si debe mostrarse el banner de ubicación
    if (isLoggedIn) {
      final geoStatus = await getStoredGeoStatus();
      _showLocBanner = geoStatus == null && !_bannerDismissed;
    }

    // Cargar feed
    await loadFeed(_ciudad);

    // Likes del usuario (solo si logueado)
    if (isLoggedIn) {
      final ids = await InteraccionService.misEncantados();
      _likedIds = ids.toSet();
      notifyListeners();
    }
  }

  // ── Cargar feed ───────────────────────────────────────────────────────────────
  Future<void> loadFeed([String? ciudad]) async {
    _feedLoading = true;
    notifyListeners();
    try {
      final data = await ExploreService.getFeed(ciudad: ciudad ?? _ciudad);
      _feed        = ExploreFeed.fromJson(data);
      _feedVersion++;
    } catch (_) {
      _feed ??= ExploreFeed.empty;
    }
    _feedLoading = false;
    notifyListeners();
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
    _searchTimer?.cancel();
    super.dispose();
  }
}
