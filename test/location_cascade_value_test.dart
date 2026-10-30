import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/shared/location_cascade_input.dart';

void main() {
  test('conserva el municipio y limpia la división cuando corresponde', () {
    const value = LocationCascadeValue(
      paisCodigo: 'CO',
      divisionCodigo: 'dept-1',
      divisionTipo: 'departamento',
      municipioCodigo: 'mun-1',
      municipio: 'Medellín',
      address: 'Calle 1',
    );

    final changedCountry = value.copyWith(
      paisCodigo: 'MX',
      clearDivision: true,
      clearMunicipio: true,
    );

    expect(changedCountry.paisCodigo, 'MX');
    expect(changedCountry.divisionCodigo, isNull);
    expect(changedCountry.municipioCodigo, isNull);
    expect(changedCountry.municipio, '');
    expect(changedCountry.address, 'Calle 1');
  });

  test('serializa la ubicación con el municipio elegido', () {
    const value = LocationCascadeValue(
      paisCodigo: 'CO',
      divisionCodigo: 'dept-1',
      divisionTipo: 'departamento',
      municipioCodigo: 'mun-1',
      municipio: 'Medellín',
    );

    expect(value.hasMunicipio, isTrue);
    expect(value.toUbicacionJson()['municipioCodigo'], 'mun-1');
  });
}
