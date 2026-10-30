import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/menu/editor/live/editor_models.dart';

void main() {
  test('parsea menú del editor con catálogo, tema y suscripción', () {
    final menu = LiveMenu.fromJson({
      'codigo': 'Menu1',
      'slug': 'joraf',
      'status': 'published',
      'esPropio': true,
      'subscription': {
        'estado': 'ACTIVE',
        'tipoPlan': 'basico',
        'limiteProductosTotal': 50,
        'diasRestantes': 12,
      },
      'cupon': {'estado': 'ACTIVO', 'diasRestantes': 5},
      'logrosDias': 3,
      'draft': {
        'info': {
          'name': 'JORAF',
          'logoUrl': 'https://img/logo.webp',
          'ubicacion': {'municipioCodigo': 'Mun1'},
          'galeria': ['https://img/1.jpg'],
        },
        'design': {'skinId': 'skin-1', 'paletteId': 'pal-1'},
        'categories': [
          {'id': 'Cat1', 'name': 'Burgers', 'isVisible': true},
        ],
        'products': [
          {
            'id': 'Prod1',
            'categoryId': 'Cat1',
            'name': 'Clásica',
            'price': 15000,
            'sizes': [
              {'label': 'Doble', 'price': 5000},
            ],
          },
        ],
        'grupos': [
          {
            'id': 'G1',
            'name': 'Salsas',
            'items': [
              {'name': 'BBQ', 'price': 2000},
            ],
          },
        ],
      },
    });

    expect(menu.codigo, 'Menu1');
    expect(menu.publicado, isTrue);
    expect(menu.puedeGestionar, isTrue);
    expect(menu.info.municipioCodigo, 'Mun1');
    expect(menu.skinId, 'skin-1');
    expect(menu.categories.single.codigo, 'Cat1');
    expect(menu.products.single.sizes.single['price'], 5000);
    expect(menu.groups.single.items.single['name'], 'BBQ');
    expect(menu.subscription.activa, isTrue);
    expect(menu.tieneBeneficio, isTrue);
    expect(menu.tieneAcceso, isTrue);
  });

  test('colaborador mesero no gestiona y no tiene acceso de publicación', () {
    final menu = LiveMenu.fromJson({
      'codigo': 'Menu2',
      'slug': 'menu-2',
      'esPropio': false,
      'miRol': 'mesero',
      'draft': {},
    });

    expect(menu.puedeGestionar, isFalse);
    expect(menu.esMesero, isTrue);
    expect(menu.tieneAcceso, isFalse);
  });
}
