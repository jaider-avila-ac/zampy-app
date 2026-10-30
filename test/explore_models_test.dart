import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/explore/models/explore_models.dart';

void main() {
  test('parsea tarjetas de menú con códigos públicos', () {
    final menu = TarjetaMenu.fromJson({
      'codigo': '4Ghxu3RiWW1o',
      'slug': 'qa-catalogo',
      'nombre': 'QA Catalogo',
      'logoUrl': 'https://img.test/logo.webp',
      'categoria': 'Comida Rápida',
      'municipio': 'Rionegro',
    });

    expect(menu.codigo, '4Ghxu3RiWW1o');
    expect(menu.nombre, 'QA Catalogo');
    expect(menu.logoUrl, isNotNull);
    expect(menu.municipio, 'Rionegro');
  });

  test('parsea tarjetas de producto y paginación', () {
    final page = ProductosPage.fromJson({
      'items': [
        {
          'codigo': 'JekyL5aSdQKA',
          'nombre': 'Patacón con Todo',
          'imagenUrl': 'https://img.test/p.jpg',
          'menuSlug': 'joraf-restaurante',
          'menuNombre': 'JORAF',
          'meEncantas': 3,
        },
      ],
      'siguiente': 'cursor-2',
    });

    expect(page.items, hasLength(1));
    expect(page.items.first.codigo, 'JekyL5aSdQKA');
    expect(page.items.first.meEncantas, 3);
    expect(page.siguiente, 'cursor-2');
  });

  test('parsea filtros de lugares y categorías', () {
    final filtros = ExploreFiltros.fromJson({
      'categorias': [
        {'codigo': 'cat-1', 'nombre': 'Comida Rápida', 'detalle': 'zap'},
      ],
      'lugares': [
        {'codigo': 'mun-1', 'nombre': 'Rionegro', 'detalle': 'Antioquia'},
      ],
    });

    expect(filtros.categorias.first.codigo, 'cat-1');
    expect(filtros.lugares.first.nombre, 'Rionegro');
  });
}
