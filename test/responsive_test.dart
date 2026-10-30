import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/shared/responsive.dart';

Future<EdgeInsets> _padding(WidgetTester tester, double ancho) async {
  late EdgeInsets p;
  await tester.pumpWidget(MediaQuery(
    data: MediaQueryData(size: Size(ancho, 900)),
    child: Builder(builder: (context) {
      p = contenidoPadding(context);
      return const SizedBox();
    }),
  ));
  return p;
}

void main() {
  testWidgets('en teléfono usa el margen normal', (tester) async {
    final p = await _padding(tester, 390);
    expect(p.left, 16);
    expect(p.right, 16);
  });

  testWidgets('en tablet centra el contenido en 720', (tester) async {
    final p = await _padding(tester, 1024);
    expect(p.left, (1024 - 720) / 2);
    expect(1024 - p.left - p.right, 720);
  });

  testWidgets('el corte de tablet es 600', (tester) async {
    late bool tablet;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(768, 1024)),
      child: Builder(builder: (context) {
        tablet = esTablet(context);
        return const SizedBox();
      }),
    ));
    expect(tablet, isTrue);
  });
}
