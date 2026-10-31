import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/menu/public/edicion/edicion_menu.dart';
import 'package:zammpy_app/modules/menu/public/edicion/editable.dart';
import 'package:zammpy_app/modules/menu/public/edicion/panel/secciones.dart';
import 'package:zammpy_app/modules/menu/public/edicion/producto/producto_editable.dart';
import 'package:zammpy_app/modules/menu/public/models/public_menu_model.dart';

const _producto = MenuProduct(id: 'P1', name: 'Hamburguesa', price: 18000, categoryId: 'C1', isVisible: false);

Widget _app(Widget child, {List<String>? abiertas}) => MaterialApp(
      home: Scaffold(
        body: abiertas == null
            ? child
            : EdicionMenu(
                abrir: (seccion, [datos]) => abiertas.add(seccion),
                menuCodigo: 'MENU1',
                recargar: () async {},
                child: child,
              ),
      ),
    );

void main() {
  testWidgets('sin edición activa la portada no abre nada y el producto se ve tal cual', (tester) async {
    var tocado = false;
    await tester.pumpWidget(_app(Column(
      children: [
        Editable(
          seccion: 'portada',
          etiqueta: 'Portada',
          child: TextButton(onPressed: () => tocado = true, child: const Text('portada')),
        ),
        const ProductoEditable(producto: _producto, child: SizedBox(height: 120, child: Text('tarjeta'))),
      ],
    )));
    await tester.tap(find.text('portada'));
    expect(tocado, isTrue); // el botón de adentro funciona normal
    expect(find.text('Oculto'), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
  });

  testWidgets('editando, tocar la portada abre su sección y no lo de adentro', (tester) async {
    final abiertas = <String>[];
    var tocado = false;
    await tester.pumpWidget(_app(
      Editable(
        seccion: 'portada',
        etiqueta: 'Portada',
        child: TextButton(onPressed: () => tocado = true, child: const Text('portada')),
      ),
      abiertas: abiertas,
    ));
    await tester.tap(find.text('portada'));
    expect(abiertas, ['portada']);
    expect(tocado, isFalse);
  });

  testWidgets('editando, el producto oculto se marca y su "⋯" abre cada parte', (tester) async {
    final abiertas = <String>[];
    await tester.pumpWidget(_app(
      const SizedBox(
        width: 200,
        height: 260,
        child: ProductoEditable(producto: _producto, child: SizedBox.expand(child: Text('tarjeta'))),
      ),
      abiertas: abiertas,
    ));
    expect(find.text('Oculto'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Mostrar en el menú'), findsOneWidget); // está oculto
    expect(find.text('Tamaños'), findsOneWidget);
    await tester.tap(find.text('Tamaños'));
    await tester.pumpAndSettle();
    expect(abiertas, ['producto:tamanos']);
  });

  test('títulos de sección iguales a los de React', () {
    expect(tituloSeccion('informacion', null), 'Información del negocio');
    expect(tituloSeccion('producto:promocion', _producto), 'Promoción · Hamburguesa');
  });
}
