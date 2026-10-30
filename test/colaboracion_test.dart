import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/menu/editor/live/editor_models.dart';
import 'package:zammpy_app/services/colaboracion_service.dart';

void main() {
  test('Colaborador usa el código de usuario y rol editor por defecto', () {
    final c = Colaborador.fromJson({
      'codigo': 'AB12CD',
      'nombre': 'Ana',
      'apellido': 'Ruiz',
      'avatar': null,
      'rol': null,
    });
    expect(c.codigo, 'AB12CD');
    expect(c.rol, 'editor');
    expect(c.nombreCompleto, 'Ana Ruiz');
  });

  test('LiveMenu lee transferible y lo asume true si no viene', () {
    expect(LiveMenu.fromJson({'codigo': 'x'}).transferible, isTrue);
    expect(
      LiveMenu.fromJson({'codigo': 'x', 'transferible': false}).transferible,
      isFalse,
    );
  });
}
