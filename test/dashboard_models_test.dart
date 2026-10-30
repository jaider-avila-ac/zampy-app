import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/dashboard/models/dashboard_models.dart';

void main() {
  test('parsea tarjetas propias y límite del plan', () {
    final data = MisMenusData.fromJson({
      'limiteMenus': 3,
      'items': [
        {
          'codigo': 'Menu1',
          'slug': 'joraf',
          'nombre': 'JORAF',
          'categoria': 'Comida Rápida',
          'municipio': 'San Antero',
          'estado': 'publicado',
        },
        {
          'codigo': 'Menu2',
          'slug': 'qa-catalogo',
          'nombre': 'QA Catalogo',
          'estado': 'borrador',
        },
      ],
    });

    expect(data.limiteMenus, 3);
    expect(data.items, hasLength(2));
    expect(data.items.first.codigo, 'Menu1');
    expect(data.items.first.estado, 'publicado');
  });

  test('parsea colaboración con rol y borrador', () {
    final menu = ColaboracionMenu.fromJson({
      'codigo': 'Menu3',
      'slug': 'menu-3',
      'status': 'publicado',
      'miRol': 'mesero',
      'draft': {
        'info': {'name': 'Café Central', 'slogan': 'Buen café'},
      },
    });

    expect(menu.codigo, 'Menu3');
    expect(menu.nombre, 'Café Central');
    expect(menu.rolLabel, 'Mesero');
    expect(menu.publicado, isTrue);
  });

  test('parsea resumen del hub con pasos y permisos', () {
    final menu = MenuResumen.fromJson({
      'codigo': 'Menu4',
      'slug': 'menu-4',
      'status': 'borrador',
      'esPropio': true,
      'draft': {
        'info': {'name': 'Mi menú'},
      },
      'pasos': [
        {'codigo': 'imagenes', 'completo': true, 'obligatorio': true},
        {'codigo': 'productos', 'completo': false, 'obligatorio': true},
      ],
    });

    expect(menu.nombre, 'Mi menú');
    expect(menu.publicado, isFalse);
    expect(menu.puedeGestionar, isTrue);
    expect(menu.pasos, hasLength(2));
    expect(menu.pasos.last.codigo, 'productos');
    expect(menu.pasos.last.obligatorio, isTrue);
  });

  test('colaborador editor puede gestionar y mesero no', () {
    final editor = MenuResumen.fromJson({
      'codigo': 'Menu5',
      'slug': 'menu-5',
      'esPropio': false,
      'miRol': 'editor',
    });
    final mesero = MenuResumen.fromJson({
      'codigo': 'Menu6',
      'slug': 'menu-6',
      'esPropio': false,
      'miRol': 'mesero',
    });

    expect(editor.puedeGestionar, isTrue);
    expect(mesero.puedeGestionar, isFalse);
    expect(mesero.esMesero, isTrue);
  });
}
