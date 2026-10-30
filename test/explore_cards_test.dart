import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/explore/components/filtros.dart';
import 'package:zammpy_app/modules/explore/components/menu_card.dart';
import 'package:zammpy_app/modules/explore/components/producto_card.dart';
import 'package:zammpy_app/modules/explore/models/explore_models.dart';

void main() {
  testWidgets('MenuCard renderiza nombre, categoría y municipio', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: MenuCard(
              menu: const TarjetaMenu(
                codigo: 'menu-1',
                slug: 'menu-de-prueba',
                nombre: 'Un nombre de restaurante bastante largo',
                categoria: 'Comida Rápida',
                municipio: 'Rionegro',
              ),
              conSesion: false,
              onTap: () {},
              onToggleLike: () {},
              onRequireLogin: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Un nombre'), findsOneWidget);
    expect(find.text('Comida Rápida'), findsOneWidget);
    expect(find.text('Rionegro'), findsOneWidget);
  });

  testWidgets('ProductoCard renderiza sin imagen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: ProductoCard(
              producto: const TarjetaProducto(
                codigo: 'prod-1',
                nombre: 'Patacón con Todo',
                menuSlug: 'menu-de-prueba',
                menuNombre: 'JORAF',
                meEncantas: 2,
              ),
              conSesion: false,
              onTap: () {},
              onToggleLike: () {},
              onRequireLogin: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Patacón con Todo'), findsOneWidget);
    expect(find.text('JORAF'), findsOneWidget);
  });

  testWidgets('Filtros muestra todos los lugares y categorías', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Filtros(
            filtros: const ExploreFiltros(
              categorias: [
                ExploreFiltroOpcion(codigo: 'cat-1', nombre: 'Comida Rápida', detalle: 'zap'),
              ],
              lugares: [
                ExploreFiltroOpcion(codigo: 'mun-1', nombre: 'Rionegro', detalle: 'Antioquia'),
              ],
            ),
            municipio: null,
            categoria: null,
            onMunicipio: (_) {},
            onCategoria: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Todos los lugares'), findsOneWidget);
    expect(find.text('Todo'), findsOneWidget);
    expect(find.text('Comida Rápida'), findsOneWidget);
  });
}
