import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zammpy_app/context/auth_context.dart';
import 'package:zammpy_app/modules/auth/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders the authentication form', (tester) async {
    final auth = AuthContext();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthContext>.value(
        value: auth,
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}
