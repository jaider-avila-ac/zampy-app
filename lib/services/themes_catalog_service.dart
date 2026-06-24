import 'dart:convert';
import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;
import 'api.dart';
import '../modules/menu/public/models/public_menu_model.dart';

// Equivalente al módulo singleton themesCatalog.js de React
// GET /api/v1/public/themes → lista de skins con paletas

class CatalogPalette {
  final dynamic    id;
  final String     name;
  final List<String> preview;
  final String     fontHeading;
  final String     fontBody;
  final Map<String, dynamic> _colors;
  final Map<String, dynamic> _radius;

  const CatalogPalette({
    required this.id,
    required this.name,
    required this.preview,
    required this.fontHeading,
    required this.fontBody,
    required Map<String, dynamic> colors,
    required Map<String, dynamic> radius,
  })  : _colors = colors,
        _radius = radius;

  factory CatalogPalette.fromJson(Map<String, dynamic> json) => CatalogPalette(
        id:          json['id'],
        name:        json['nombre']      as String? ?? '',
        preview:     (json['preview']    as List?)?.cast<String>() ?? [],
        fontHeading: json['fontHeading'] as String? ?? 'inter',
        fontBody:    json['fontBody']    as String? ?? 'inter',
        colors:      (json['colors']     as Map?)?.cast<String, dynamic>() ?? {},
        // backend envía radius como números: { card: 12, button: 8, badge: 99 }
        radius:      (json['radius']     as Map?)?.cast<String, dynamic>() ?? {},
      );

  Map<String, dynamic> get colors       => _colors;
  // Devuelve los valores crudos del backend (números); usar _parseRadius para convertir
  Map<String, dynamic> get borderRadius => _radius;

  MenuTheme toMenuTheme(String skinId) => MenuTheme.fromJson({
        'skinId': skinId,
        'colors': _colors,
        'radius': _radius,
      });
}

class CatalogSkin {
  final dynamic              id;
  final String               label;
  final String               description;
  final int                  orden;
  final List<CatalogPalette> palettes;

  const CatalogSkin({
    required this.id,
    required this.label,
    required this.description,
    required this.orden,
    required this.palettes,
  });

  factory CatalogSkin.fromJson(Map<String, dynamic> json) => CatalogSkin(
        id:          json['id'],
        label:       json['label']      as String? ?? '',
        description: json['descripcion'] as String? ?? '',
        orden:       (json['orden']     as num?)?.toInt() ?? 0,
        palettes:    (json['paletas']   as List? ?? [])
            .map((p) => CatalogPalette.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

// Singleton en memoria — equivalente al _cache del módulo JS
List<CatalogSkin>? _catalogCache;

class ThemesCatalogService {
  ThemesCatalogService._();

  static Future<List<CatalogSkin>> load() async {
    if (_catalogCache != null) return _catalogCache!;
    try {
      final res = await http
          .get(Uri.parse('$kApiBase/api/v1/public/themes'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      _catalogCache = list
          .map((s) => CatalogSkin.fromJson(s as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.orden.compareTo(b.orden));
      return _catalogCache!;
    } catch (_) {
      return [];
    }
  }

  // Equivalente a resolveSkin + resolvePalette en ThemeContext.jsx
  // skinId y paletteId pueden ser int o String (el demo usa strings "fastfood"/"ember")
  static MenuTheme resolveTheme(
    List<CatalogSkin> catalog,
    dynamic skinId,
    dynamic paletteId,
  ) {
    if (catalog.isEmpty) return const MenuTheme(primary: Color(0xFF4F46E5));

    final skin = catalog.firstWhere(
      (s) => s.id.toString() == skinId?.toString(),
      orElse: () => catalog.first,
    );

    if (skin.palettes.isEmpty) return const MenuTheme(primary: Color(0xFF4F46E5));

    final palette = skin.palettes.firstWhere(
      (p) => p.id.toString() == paletteId?.toString(),
      orElse: () => skin.palettes.first,
    );

    return palette.toMenuTheme(skin.id.toString());
  }

  // Helper: encuentra un skin por id (int o String)
  static CatalogSkin? findSkin(List<CatalogSkin> catalog, dynamic skinId) {
    if (catalog.isEmpty) return null;
    return catalog.firstWhere(
      (s) => s.id.toString() == skinId?.toString(),
      orElse: () => catalog.first,
    );
  }

  // Helper: encuentra una paleta por id dentro de un skin
  static CatalogPalette? findPalette(CatalogSkin skin, dynamic paletteId) {
    if (skin.palettes.isEmpty) return null;
    return skin.palettes.firstWhere(
      (p) => p.id.toString() == paletteId?.toString(),
      orElse: () => skin.palettes.first,
    );
  }
}
