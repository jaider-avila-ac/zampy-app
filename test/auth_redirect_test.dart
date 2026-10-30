import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/services/auth_redirect.dart';

void main() {
  test('guarda y consume el destino pendiente', () {
    AuthRedirect.clear();
    AuthRedirect.remember('/menus/abc123');
    expect(AuthRedirect.consume(), '/menus/abc123');
    expect(AuthRedirect.consume(), isNull);
  });

  test('no guarda la pantalla de login como destino', () {
    AuthRedirect.clear();
    AuthRedirect.remember('/login');
    expect(AuthRedirect.consume(), isNull);
  });
}
