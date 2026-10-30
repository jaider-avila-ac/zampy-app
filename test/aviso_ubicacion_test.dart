import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zammpy_app/components/layout/aviso_ubicacion.dart';
import 'package:zammpy_app/context/auth_context.dart';

const _texto = 'Agrega tu municipio para ver lugares y promociones cerca de ti.';

Future<GoRouter> _montar(WidgetTester tester, AuthContext auth) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('explore'))),
      GoRoute(path: '/perfil', builder: (_, _) => const Scaffold(body: Text('perfil'))),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      builder: (context, child) =>
          AvisoUbicacion(auth: auth, router: router, child: child!),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('muestra el aviso sin municipio y lleva al perfil', (tester) async {
    final auth = AuthContext();
    await auth.login({'token': 't', 'email': 'a@b.co', 'requiereUbicacion': true});
    await _montar(tester, auth);

    expect(find.text(_texto), findsOneWidget);

    await tester.tap(find.text('Completar'));
    await tester.pumpAndSettle();
    expect(find.text('perfil'), findsOneWidget);
    // En /perfil ya no se repite el aviso.
    expect(find.text(_texto), findsNothing);
  });

  testWidgets('se oculta al guardar la ubicación', (tester) async {
    final auth = AuthContext();
    await auth.login({'token': 't', 'email': 'a@b.co', 'requiereUbicacion': true});
    await _montar(tester, auth);
    expect(find.text(_texto), findsOneWidget);

    await auth.updateUser({'requiereUbicacion': false});
    await tester.pumpAndSettle();
    expect(find.text(_texto), findsNothing);
  });

  testWidgets('no aparece sin sesión', (tester) async {
    await _montar(tester, AuthContext());
    expect(find.text(_texto), findsNothing);
  });
}
