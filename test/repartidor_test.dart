import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/repartidor/components/pedido_repartidor_card.dart';
import 'package:zammpy_app/modules/repartidor/models/pedido_repartidor.dart';

// Fase 16: modo repartidor.

final _disponible = <String, dynamic>{
  'codigo': 'PED1',
  'estado': 'pendiente',
  'total': 32000,
  'asignadoAMi': false,
  // sin asignar, el backend no envía los datos del cliente
  'usrNombre': null,
  'usrDireccion': null,
  'items': [
    {'productName': 'Pizza', 'quantity': 1},
    {'productName': 'Gaseosa', 'quantity': 2},
    {'productName': 'Postre', 'quantity': 1},
    {'productName': 'Salsa', 'quantity': 1},
  ],
};

final _mio = <String, dynamic>{
  ..._disponible,
  'codigo': 'PED2',
  'estado': 'en_proceso',
  'asignadoAMi': true,
  'usrNombre': 'Carlos Ruiz',
  'usrTelefono': '3009876543',
  'usrDireccion': 'Cra 7 # 12-30',
  'usrDireccionReferencia': 'Apto 501',
};

Future<void> _montar(WidgetTester tester, Widget child, {double ancho = 360}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(ancho, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))));
}

void main() {
  test('modelo: disponible vs asignado y métricas del día', () {
    final d = PedidoRepartidor.fromJson(_disponible);
    expect(d.disponible, isTrue);
    expect(d.pedido.clienteNombre, isNull);
    final m = PedidoRepartidor.fromJson(_mio);
    expect(m.disponible, isFalse);
    expect(m.activo, isTrue);
    final met = MetricasRepartidor.fromJson({'totalEntregas': 4, 'cancelados': 1, 'totalCobrado': 98000});
    expect((met.entregas, met.cancelados, met.cobrado), (4, 1, 98000));
  });

  testWidgets('pedido disponible: se toma, sin datos de entrega', (tester) async {
    var tomado = false;
    await _montar(
      tester,
      PedidoRepartidorCard(
        item: PedidoRepartidor.fromJson(_disponible),
        actualizando: null,
        onTomar: () => tomado = true,
        onCambiarEstado: (_) {},
        onCancelar: () {},
      ),
    );
    expect(find.text('Pedido disponible'), findsOneWidget);
    expect(find.text('Toma el pedido para ver los datos de entrega.'), findsOneWidget);
    expect(find.text('+1 más'), findsOneWidget);
    await tester.tap(find.text('Tomar pedido'));
    expect(tomado, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final ancho in [320.0, 1024.0]) {
    testWidgets('pedido propio en preparación: entregar o cancelar ($ancho)', (tester) async {
      String? estado;
      var cancelado = false;
      await _montar(
        tester,
        PedidoRepartidorCard(
          item: PedidoRepartidor.fromJson(_mio),
          actualizando: null,
          onTomar: () {},
          onCambiarEstado: (e) => estado = e,
          onCancelar: () => cancelado = true,
        ),
        ancho: ancho,
      );
      expect(find.text('Carlos Ruiz'), findsOneWidget);
      expect(find.text('3009876543'), findsOneWidget);
      expect(find.text('Tomar pedido'), findsNothing);
      await tester.tap(find.text('Entregado'));
      expect(estado, 'entregado');
      await tester.tap(find.text('Cancelar'));
      expect(cancelado, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('un pedido entregado no tiene acciones', (tester) async {
    await _montar(
      tester,
      PedidoRepartidorCard(
        item: PedidoRepartidor.fromJson({..._mio, 'estado': 'entregado'}),
        actualizando: null,
        onTomar: () {},
        onCambiarEstado: (_) {},
        onCancelar: () {},
      ),
    );
    expect(find.text('Cancelar'), findsNothing);
    expect(find.text('Tomar pedido'), findsNothing);
  });
}
