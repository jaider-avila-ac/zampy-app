import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/menu/create/models/create_menu_models.dart';

void main() {
  test('slugify genera el link desde el nombre y conserva guiones', () {
    expect(slugify('Pizzería La Napolitana'), 'pizzeria-la-napolitana');
    expect(slugify('  Café & Pan  '), 'cafe-pan');
    expect(slugify('A' * 80).length, 50);
  });

  test('slugError valida el contrato del link', () {
    expect(slugError('mi-pizzeria'), isNull);
    expect(slugError('ab'), 'Mínimo 3 caracteres');
    expect(slugError('Mi Pizza'), isNotNull);
    expect(slugError('-mi-pizza'), isNotNull);
    expect(slugError('mi--pizza'), isNotNull);
  });

  test(
    'el payload de creación solo envía lo básico con código de categoría',
    () {
      final payload = const CrearMenuDraft(
        restaurantCategoryCode: 'cat-1',
        name: '  JORAF  ',
        slug: 'joraf',
      ).toJson();

      expect(payload, {
        'restaurantCategoryCode': 'cat-1',
        'name': 'JORAF',
        'slug': 'joraf',
      });
    },
  );

  test('parsea categorías del backend', () {
    final categoria = CategoriaRestaurante.fromJson({
      'codigo': 'cat-1',
      'nombre': 'Comida Rápida',
      'icono': 'zap',
    });

    expect(categoria.codigo, 'cat-1');
    expect(categoria.nombre, 'Comida Rápida');
    expect(categoria.icono, 'zap');
  });
}
