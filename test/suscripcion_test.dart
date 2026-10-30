import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/subscription/utils/sus_format.dart';
import 'package:zammpy_app/services/suscripcion_service.dart';

void main() {
  test('conSus usa los códigos como id y menId, también en los pagos', () {
    final s = conSus({
      'codigo': 'SUS123',
      'menuCodigo': 'MEN456',
      'estado': 'ACTIVE',
      'pagos': [
        {'codigo': 'PAG1', 'montoCentavos': 1120000},
      ],
    });
    expect(s['id'], 'SUS123');
    expect(s['menId'], 'MEN456');
    expect((s['pagos'] as List).first['id'], 'PAG1');
  });

  test('fmtCOP formatea centavos en pesos con separador de miles', () {
    expect(fmtCOP(1120000), r'$11.200 COP');
    expect(fmtCOP(null), '—');
  });

  test('fmtTiempo elige la unidad más legible', () {
    expect(fmtTiempo(0, 45), '45 minutos');
    expect(fmtTiempo(0, 120), '2 horas');
    expect(fmtTiempo(3, null), '3 días');
    expect(fmtTiempo(0, 0), '0 minutos');
  });
}
