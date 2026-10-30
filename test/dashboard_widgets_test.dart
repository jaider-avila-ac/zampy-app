import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/dashboard/components/colaborador_row.dart';
import 'package:zammpy_app/modules/dashboard/components/delete_menu_modal.dart';
import 'package:zammpy_app/modules/dashboard/components/menu_steps.dart';
import 'package:zammpy_app/modules/dashboard/models/dashboard_models.dart';

void main() {
  testWidgets('el eliminar exige el código exacto y llama al servicio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var deletedWith = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => DeleteMenuModal.show(
                context,
                menuName: 'JORAF',
                confirmWord: 'ABCDE',
                onDelete: (code) async => deletedWith = code,
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    final confirmFinder = find.widgetWithText(
      FilledButton,
      'Eliminar definitivamente',
    );
    expect(tester.widget<FilledButton>(confirmFinder).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'abcde');
    await tester.pump();
    expect(tester.widget<FilledButton>(confirmFinder).onPressed, isNotNull);

    await tester.tap(confirmFinder);
    await tester.pumpAndSettle();
    expect(deletedWith, 'ABCDE');
  });

  testWidgets('pasos muestra progreso y permite abrir un paso', (tester) async {
    PasoMenu? abierto;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MenuSteps(
            pasos: const [
              PasoMenu(codigo: 'imagenes', completo: true, obligatorio: true),
              PasoMenu(codigo: 'productos', completo: false, obligatorio: true),
            ],
            onTap: (paso) => abierto = paso,
          ),
        ),
      ),
    );

    expect(find.text('Completa tu menú'), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);
    expect(find.text('Categorías y productos'), findsOneWidget);

    await tester.tap(find.text('Categorías y productos'));
    await tester.pump();
    expect(abierto?.codigo, 'productos');
  });

  testWidgets('colaborador muestra su rol', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColaboradorRow(
            menu: const ColaboracionMenu(
              codigo: 'Menu1',
              slug: 'menu-1',
              nombre: 'Café Central',
              estado: 'publicado',
              miRol: 'mesero',
            ),
            onOpen: () {},
          ),
        ),
      ),
    );

    expect(find.text('Café Central'), findsOneWidget);
    expect(find.text('Mesero'), findsOneWidget);
    expect(find.text('Publicado'), findsOneWidget);
  });
}
