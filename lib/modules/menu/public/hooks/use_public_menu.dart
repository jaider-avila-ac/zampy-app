import 'dart:convert';
import 'package:flutter/material.dart' hide MenuTheme;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../services/api.dart';
import '../../../../services/themes_catalog_service.dart';
import '../models/public_menu_model.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

// Equivalente a src/modules/menu/public/hooks/usePublicMenu.js en React

class UsePublicMenu extends ChangeNotifier {
  // Un client por instancia — se cierra en dispose() para cancelar
  // cualquier request en vuelo cuando el usuario sale del menú.
  // Esto evita que siga descargando imágenes/datos de un menú que ya no se ve.
  final _client   = http.Client();
  bool  _disposed = false;

  PublicMenuData? _menuData;
  bool    _loading  = true;
  bool    _notFound = false;
  String  _slug     = '';

  PublicMenuData? get menuData => _menuData;
  bool            get loading  => _loading;
  bool            get notFound => _notFound;
  String          get slug     => _slug;

  Future<void> load({String? slug, bool isDemo = false, String? previewId}) async {
    _loading  = true;
    _notFound = false;
    _menuData = null;
    if (!_disposed) notifyListeners();

    try {
      final data = isDemo
          ? await _getDemoData(_client)
          : previewId != null
              ? await _getPreviewData(previewId, _client)
              : await _getPublicData(slug!, _client);

      if (_disposed) return; // el usuario ya salió — no actualizar estado
      if (data == null) {
        _notFound = true;
      } else {
        _menuData = data;
        _slug     = slug ?? '';
      }
    } catch (_) {
      if (_disposed) return;
      _notFound = true;
    }
    _loading = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _client.close(); // cancela el request en vuelo si el usuario salió antes de terminar
    super.dispose();
  }

  // ── GET /api/v1/public/menu/:slug ─────────────────────────────────────────
  static Future<PublicMenuData?> _getPublicData(
      String slug, http.Client client) async {
    final results = await Future.wait([
      client
          .get(Uri.parse('$kApiBase/api/v1/public/menu/$slug'))
          .timeout(const Duration(seconds: 15)),
      ThemesCatalogService.load(),
    ]);

    final res     = results[0] as http.Response;
    final catalog = results[1] as List<CatalogSkin>;

    if (res.statusCode == 404) return null;
    if (res.statusCode < 200 || res.statusCode >= 300) return null;

    final root      = jsonDecode(res.body) as Map<String, dynamic>;
    final published = root['published'] as Map<String, dynamic>?;
    if (published == null) return null;

    final design = published['design'] as Map<String, dynamic>?;
    final theme  = ThemesCatalogService.resolveTheme(
      catalog, design?['skinId'], design?['paletteId'],
    );

    return PublicMenuData.fromJson({
      ...published,
      'menuId':  root['id'],
      'slug':    root['slug'],
      'ownerId': root['ownerId'],
      'theme':   null,
    }).copyWithTheme(theme);
  }

  // ── GET /api/v1/menus/:id/preview  (borrador del dueño) ──────────────────
  static Future<PublicMenuData?> _getPreviewData(
      String id, http.Client client) async {
    final raw  = await _storage.read(key: 'auth');
    final tok  = raw != null
        ? (jsonDecode(raw) as Map<String, dynamic>)['token'] as String?
        : null;
    final headers = tok != null ? {'Authorization': 'Bearer $tok'} : <String, String>{};

    final results = await Future.wait([
      client
          .get(Uri.parse('$kApiBase/api/v1/menus/$id/preview'), headers: headers)
          .timeout(const Duration(seconds: 15)),
      ThemesCatalogService.load(),
    ]);

    final res     = results[0] as http.Response;
    final catalog = results[1] as List<CatalogSkin>;

    if (res.statusCode == 404) return null;
    if (res.statusCode < 200 || res.statusCode >= 300) return null;

    final root   = jsonDecode(res.body) as Map<String, dynamic>;
    // El endpoint preview devuelve el draft directamente (misma forma que published)
    final draft  = root['draft'] as Map<String, dynamic>? ?? root;
    final design = draft['design'] as Map<String, dynamic>?;
    final theme  = ThemesCatalogService.resolveTheme(
      catalog, design?['skinId'], design?['paletteId'],
    );

    return PublicMenuData.fromJson({
      ...draft,
      'menuId':  root['id'],
      'slug':    root['slug']    ?? '',
      'ownerId': root['ownerId'] ?? 0,
      'theme':   null,
    }).copyWithTheme(theme);
  }

  // ── GET /api/v1/public/demo ───────────────────────────────────────────────
  static Future<PublicMenuData?> _getDemoData(http.Client client) async {
    try {
      final results = await Future.wait([
        client
            .get(Uri.parse('$kApiBase/api/v1/public/demo'))
            .timeout(const Duration(seconds: 15)),
        ThemesCatalogService.load(),
      ]);

      final res     = results[0] as http.Response;
      final catalog = results[1] as List<CatalogSkin>;

      if (res.statusCode < 200 || res.statusCode >= 300) return _staticDemoData();
      final root      = jsonDecode(res.body) as Map<String, dynamic>;
      final published = root['published'] as Map<String, dynamic>?;
      if (published == null) return _staticDemoData();

      final design = published['design'] as Map<String, dynamic>?;
      final theme  = ThemesCatalogService.resolveTheme(
        catalog, design?['skinId'], design?['paletteId'],
      );

      return PublicMenuData.fromJson({
        ...published,
        'menuId':  root['id'],
        'slug':    root['slug'],
        'ownerId': root['ownerId'],
        'theme':   null,
      }).copyWithTheme(theme);
    } catch (_) {
      return _staticDemoData();
    }
  }

  // Fallback estático si el backend no responde
  static PublicMenuData _staticDemoData() {
    return PublicMenuData(
      info: const MenuInfo(
        name: 'Burger & More',
        slogan: 'Sabor que enamora, calidad que conquista',
        bannerUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1200&q=75',
      ),
      theme: const MenuTheme(primary: Color(0xFF4F46E5)),
      categories: const [
        MenuCategory(id: 'burgers', name: 'Hamburguesas', icon: 'burger'),
        MenuCategory(id: 'drinks',  name: 'Bebidas',      icon: 'cup'),
        MenuCategory(id: 'desserts',name: 'Postres',      icon: 'cake'),
      ],
      products: const [
        MenuProduct(
          id: '1', name: 'Classic Burger', categoryId: 'burgers', price: 18000,
          description: 'Carne de res 150g, lechuga, tomate, cebolla caramelizada y salsa especial.',
          imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=75',
          tags: ['Popular'],
        ),
        MenuProduct(
          id: '2', name: 'BBQ Burger', categoryId: 'burgers', price: 22000,
          description: 'Doble carne, tocino crocante, cheddar y salsa BBQ ahumada.',
          imageUrl: 'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400&q=75',
          promoActive: true, promoPrice: 19000,
        ),
        MenuProduct(
          id: '3', name: 'Limonada Natural', categoryId: 'drinks', price: 7000,
          description: 'Limonada fresca con menta y azúcar de caña.',
        ),
        MenuProduct(
          id: '4', name: 'Brownie con Helado', categoryId: 'desserts', price: 10000,
          description: 'Brownie tibio de chocolate con bola de helado de vainilla.',
          imageUrl: 'https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=400&q=75',
        ),
      ],
    );
  }
}
