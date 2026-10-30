import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/growth/achievements/models/logro_model.dart';
import 'package:zammpy_app/services/logro_service.dart';

void main() {
  test('LogroModel usa el código y el estado de la recompensa del backend', () {
    final l = LogroModel.fromJson({
      'codigo': 'Ab12Cd34Ef56',
      'nombre': 'Primeros 10 me encanta',
      'condicion': 'ME_ENCANTAS',
      'cantidad': 10,
      'progreso': 10,
      'diasRecompensa': 7,
      'desbloqueado': true,
      'estadoRecompensa': 'APLICADO',
      'menuCodigoAplicado': 'Menu00000001',
    });
    expect(l.codigo, 'Ab12Cd34Ef56');
    expect(l.aplicado, isTrue);
    expect(l.disponible, isFalse);
    expect(l.menuCodigoAplicado, 'Menu00000001');
  });

  test('requestId cumple el patrón del backend y no se repite', () {
    final a = LogroService.nuevoRequestId();
    final b = LogroService.nuevoRequestId();
    expect(RegExp(r'^[A-Za-z0-9:_-]{8,64}$').hasMatch(a), isTrue);
    expect(a, isNot(b));
  });
}
