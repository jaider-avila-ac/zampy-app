import 'package:flutter/material.dart' hide MenuTheme;
import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/menu/public/models/public_menu_model.dart';

void main() {
  test('parsea el wrapper público con tema, códigos y ubicación', () {
    final data = PublicMenuData.fromRoot({
      'codigo': 'menu-code',
      'slug': 'menu-demo',
      'esPropio': false,
      'miRol': null,
      'status': 'published',
      'ubicacion': {
        'municipio': 'San Antero',
        'division': 'Córdoba',
        'pais': 'Colombia',
      },
      'theme': {
        'colors': {'primary': '#FF4500', 'bg': '#FFF8F0', 'text': '#1A1A1A'},
        'radius': {'card': 10, 'button': 6, 'badge': 4},
      },
      'published': {
        'info': {
          'name': 'JORAF',
          'email': 'hola@joraf.test',
          'galeria': ['https://img.test/1.webp'],
          'pedidosActivos': false,
        },
        'design': {'skinId': 'skin-1', 'paletteId': 'palette-1'},
        'categories': [
          {'id': 'cat-1', 'name': 'Burgers', 'isVisible': true, 'order': 0},
        ],
        'products': [
          {
            'id': 'prod-1',
            'name': 'Classic Burger',
            'categoryId': 'cat-1',
            'price': 13000,
            'isVisible': true,
            'isFeatured': true,
            'sizes': [
              {'label': 'Normal', 'price': 13000},
            ],
          },
        ],
        'grupos': [
          {
            'id': 'grupo-1',
            'name': 'Adiciones',
            'items': [
              {
                'id': 'item-1',
                'name': 'Queso',
                'price': 3000,
                'isActive': true,
              },
            ],
          },
        ],
      },
    });

    expect(data.menuId, 'menu-code');
    expect(data.slug, 'menu-demo');
    expect(data.publicado, isTrue);
    expect(data.theme.primary.toARGB32(), 0xFFFF4500);
    expect(data.info.locationText, 'San Antero, Córdoba, Colombia');
    expect(data.info.hasGaleria, isTrue);
    expect(data.products.first.isFeatured, isTrue);
    expect(data.products.first.sizes.first.id, 'Normal');
    expect(data.grupos.first.items.first.price, 3000);
  });

  test('conserva el tema del catálogo cuando el backend no lo envía', () {
    final data = PublicMenuData.fromRoot({
      'codigo': 'menu-2',
      'published': {
        'info': {'name': 'Demo'},
        'products': [],
        'categories': [],
      },
    }, catalogTheme: const MenuTheme(primary: Color(0xFF123456)));

    expect(data.menuId, 'menu-2');
    expect(data.theme.primary.toARGB32(), 0xFF123456);
  });
}
