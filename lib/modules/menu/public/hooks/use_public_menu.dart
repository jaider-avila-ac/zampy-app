import 'dart:convert';

import 'package:flutter/material.dart' hide MenuTheme;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../services/api_client.dart';
import '../../../../services/themes_catalog_service.dart';
import '../models/public_menu_model.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

// Equivalente a src/modules/menu/public/hooks/usePublicMenu.js en React

class UsePublicMenu extends ChangeNotifier {
  PublicMenuData? _menuData;
  bool _loading = true;
  bool _notFound = false;
  String _slug = '';
  String? _error;
  bool _staffMode = false;
  bool _esEditor = false;
  // respuesta de GET /menus/acceso cuando quien abre el menú lo puede editar: {codigo, rol, publicado, puedeEditar}
  Map<String, dynamic>? _acceso;

  PublicMenuData? get menuData => _menuData;
  bool get loading => _loading;
  bool get notFound => _notFound;
  String get slug => _slug;
  String? get error => _error;
  bool get staffMode => _staffMode;
  bool get esEditor => _esEditor;
  Map<String, dynamic>? get acceso => _acceso;

  /// Edición en el propio menú: lo ve con las opciones de edición quien puede editarlo (dueño o editor).
  bool get editando => _acceso != null;
  bool get esPropietario => _acceso?['rol'] == 'propietario';
  bool get publicado => _acceso != null ? _acceso!['publicado'] == true : (_menuData?.publicado ?? false);

  /// Vuelve a pedir el contenido sin mostrar la pantalla de carga (tras guardar una sección).
  Future<void> recargar() async {
    final codigo = _acceso?['codigo']?.toString();
    if (codigo == null) return;
    try {
      final data = await _loadPreview(codigo, incluirOcultos: true);
      if (data != null) {
        _menuData = data;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// El menú se publicó o despublicó: se vuelve a preguntar el acceso (cambia "publicado").
  Future<void> recargarAcceso() async {
    final a = await _getAcceso(_slug);
    if (a?['puedeEditar'] == true) _acceso = a;
    await recargar();
  }

  Future<void> load({
    String? slug,
    bool isDemo = false,
    String? previewId,
    bool staffMode = false,
  }) async {
    _loading = true;
    _notFound = false;
    _error = null;
    _menuData = null;
    _staffMode = staffMode;
    _esEditor = false;
    _acceso = null;
    notifyListeners();

    try {
      PublicMenuData? data;

      if (isDemo) {
        data = await _loadDemo();
      } else if (previewId != null) {
        data = await _loadPreview(previewId);
        _esEditor = true;
      } else if (slug != null && slug.isNotEmpty) {
        _slug = slug;
        final hasSession = await _hasSession();
        if (hasSession && !staffMode) {
          final acceso = await _getAcceso(slug);
          if (acceso?['puedeEditar'] == true) {
            final codigo = acceso?['codigo']?.toString();
            if (codigo != null && codigo.isNotEmpty) {
              data = await _loadPreview(codigo, incluirOcultos: true);
              _esEditor = true;
              _acceso = acceso;
            }
          }
        }
        data ??= await _loadPublic(slug);
      }

      if (data == null) {
        _notFound = true;
      } else {
        _menuData = data;
        _slug = data.slug.isNotEmpty ? data.slug : (slug ?? _slug);
      }
    } on ApiException catch (e) {
      _notFound = e.status == 404;
      _error = e.message;
    } catch (_) {
      _notFound = true;
      _error = 'No se pudo cargar el menú.';
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> _hasSession() async {
    try {
      final raw = await _storage.read(key: 'auth');
      if (raw == null) return false;
      final token =
          (jsonDecode(raw) as Map<String, dynamic>)['token'] as String?;
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _getAcceso(String slug) async {
    try {
      final data = await ApiClient.instance.get(
        '/api/v1/menus/acceso',
        query: {'slug': slug},
      );
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PublicMenuData?> _loadPublic(String slug) async {
    ApiException? lastError;
    for (var intento = 0; intento < 3; intento++) {
      try {
        final data = await ApiClient.instance.get(
          '/api/v1/public/menu/$slug',
          auth: false,
        );
        if (data is Map) {
          final root = Map<String, dynamic>.from(data);
          if (root['published'] is! Map) return null;
          final theme = await _fallbackTheme(root);
          return PublicMenuData.fromRoot(root, catalogTheme: theme);
        }
        return null;
      } on ApiException catch (e) {
        lastError = e;
        if (e.status == 404) return null;
        if (intento < 2) {
          await Future.delayed(Duration(milliseconds: 700 * (intento + 1)));
        }
      }
    }
    if (lastError != null) throw lastError;
    return null;
  }

  Future<PublicMenuData?> _loadPreview(String codigo, {bool incluirOcultos = false}) async {
    final data = await ApiClient.instance.get('/api/v1/menus/$codigo/preview');
    if (data is! Map) return null;
    final root = Map<String, dynamic>.from(data);
    final theme = await _fallbackTheme(root, preferirBorrador: true);
    // En edición se usa el borrador (lo que el dueño edita), igual que React,
    // nunca el snapshot publicado (que puede estar vacío o desfasado).
    return PublicMenuData.fromRoot(
      root,
      catalogTheme: theme,
      incluirOcultos: incluirOcultos,
      preferirBorrador: true,
    );
  }

  Future<PublicMenuData?> _loadDemo() async {
    try {
      final data = await ApiClient.instance.get(
        '/api/v1/public/demo',
        auth: false,
      );
      if (data is! Map) return _staticDemoData();
      final root = Map<String, dynamic>.from(data);
      if (root['published'] is! Map) return _staticDemoData();
      final theme = await _fallbackTheme(root);
      return PublicMenuData.fromRoot(root, catalogTheme: theme);
    } catch (_) {
      return _staticDemoData();
    }
  }

  Future<MenuTheme?> _fallbackTheme(
    Map<String, dynamic> root, {
    bool preferirBorrador = false,
  }) async {
    if (root['theme'] is Map) return null;
    final catalog = await ThemesCatalogService.load();
    if (catalog.isEmpty) return null;
    Map? asDesign(dynamic v) => v is Map ? (v['design'] as Map?) : null;
    // En edición el diseño sale del borrador (como el contenido); en la vista
    // pública, del snapshot publicado.
    final design = preferirBorrador
        ? (asDesign(root['draft']) ??
              asDesign(root['published']) ??
              (root['design'] as Map?))
        : (asDesign(root['published']) ?? (root['design'] as Map?));
    return ThemesCatalogService.resolveTheme(
      catalog,
      design?['skinId'],
      design?['paletteId'],
    );
  }

  static PublicMenuData _staticDemoData() {
    return PublicMenuData(
      info: const MenuInfo(
        name: 'Burger & More',
        slogan: 'Sabor que enamora, calidad que conquista',
        bannerUrl:
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1200&q=75',
      ),
      theme: const MenuTheme(primary: Color(0xFF4F46E5)),
      categories: const [
        MenuCategory(id: 'burgers', name: 'Hamburguesas', icon: 'burger'),
        MenuCategory(id: 'drinks', name: 'Bebidas', icon: 'cup'),
        MenuCategory(id: 'desserts', name: 'Postres', icon: 'cake'),
      ],
      products: const [
        MenuProduct(
          id: '1',
          name: 'Classic Burger',
          categoryId: 'burgers',
          price: 18000,
          description:
              'Carne de res 150g, lechuga, tomate, cebolla caramelizada y salsa especial.',
          imageUrl:
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=75',
          tags: ['Popular'],
        ),
        MenuProduct(
          id: '2',
          name: 'BBQ Burger',
          categoryId: 'burgers',
          price: 22000,
          description:
              'Doble carne, tocino crocante, cheddar y salsa BBQ ahumada.',
          imageUrl:
              'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400&q=75',
          promoActive: true,
          promoPrice: 19000,
        ),
        MenuProduct(
          id: '3',
          name: 'Limonada Natural',
          categoryId: 'drinks',
          price: 7000,
          description: 'Limonada fresca con menta y azúcar de caña.',
        ),
        MenuProduct(
          id: '4',
          name: 'Brownie con Helado',
          categoryId: 'desserts',
          price: 10000,
          description:
              'Brownie tibio de chocolate con bola de helado de vainilla.',
          imageUrl:
              'https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=400&q=75',
        ),
      ],
      slug: 'demo',
      publicado: false,
    );
  }
}
