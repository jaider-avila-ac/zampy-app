import 'dart:convert';
import 'package:flutter/material.dart' hide MenuTheme;
import 'package:http/http.dart' as http;
import '../../../../services/api.dart';
import '../models/public_menu_model.dart';

// Equivalente a src/modules/menu/public/hooks/usePublicMenu.js en React

class UsePublicMenu extends ChangeNotifier {
  PublicMenuData? _menuData;
  bool  _loading  = true;
  bool  _notFound = false;

  PublicMenuData? get menuData => _menuData;
  bool            get loading  => _loading;
  bool            get notFound => _notFound;

  Future<void> load({String? slug, bool isDemo = false}) async {
    _loading  = true;
    _notFound = false;
    _menuData = null;
    notifyListeners();

    try {
      final data = isDemo
          ? await _getDemoData()
          : await _getPublicData(slug!);
      if (data == null) {
        _notFound = true;
      } else {
        _menuData = data;
      }
    } catch (_) {
      _notFound = true;
    }
    _loading = false;
    notifyListeners();
  }

  // GET /api/v1/public/menu/:slug
  // El backend devuelve { id, slug, ownerId, theme, published: { info, categories, products } }
  // React hace: { ...menu.published, menuId: menu.id, slug, ownerId, theme }
  static Future<PublicMenuData?> _getPublicData(String slug) async {
    final res = await http
        .get(Uri.parse('$kApiBase/api/v1/public/menu/$slug'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 404) return null;
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    final root      = jsonDecode(res.body) as Map<String, dynamic>;
    final published = root['published'] as Map<String, dynamic>?;
    if (published == null) return null;
    return PublicMenuData.fromJson({
      ...published,
      'menuId':  root['id'],
      'slug':    root['slug'],
      'ownerId': root['ownerId'],
      'theme':   root['theme'],
    });
  }

  // GET /api/v1/public/demo — mismo formato que getPublicData
  static Future<PublicMenuData?> _getDemoData() async {
    try {
      final res = await http
          .get(Uri.parse('$kApiBase/api/v1/public/demo'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) return _staticDemoData();
      final root      = jsonDecode(res.body) as Map<String, dynamic>;
      final published = root['published'] as Map<String, dynamic>?;
      if (published == null) return _staticDemoData();
      return PublicMenuData.fromJson({
        ...published,
        'menuId':  root['id'],
        'slug':    root['slug'],
        'ownerId': root['ownerId'],
        'theme':   root['theme'],
      });
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
