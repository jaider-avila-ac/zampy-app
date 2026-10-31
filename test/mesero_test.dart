import 'package:flutter/material.dart' hide MenuTheme;
import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/menu/public/components/order_sheet.dart';
import 'package:zammpy_app/modules/menu/public/models/public_menu_model.dart';
import 'package:zammpy_app/modules/mesero/components/mesa_card.dart';
import 'package:zammpy_app/modules/mesero/components/panel/cabecera_cuenta.dart';
import 'package:zammpy_app/modules/mesero/components/panel/ronda_card.dart';
import 'package:zammpy_app/modules/mesero/hooks/acciones_mesero.dart';
import 'package:zammpy_app/modules/mesero/hooks/use_orden_mesero.dart';
import 'package:zammpy_app/modules/mesero/models/mesa_mesero.dart';
import 'package:zammpy_app/modules/mesero/utils/tomar_orden.dart';
import 'package:zammpy_app/modules/orders/models/cuenta_mesa.dart';
import 'package:zammpy_app/modules/orders/utils/order_items.dart';

// Fase 15: modo mesero.

Future<void> _montar(WidgetTester tester, Widget child, {double ancho = 390}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(ancho, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))));
}

Map<String, dynamic> _item(String nombre, num precio) => {
      'productId': nombre,
      'productName': nombre,
      'unitPrice': precio,
      'quantity': 1,
      'ingredientIds': <String>[],
      'extraIds': <String>[],
      'grupos': <String, dynamic>{},
    };

CuentaMesa _cuenta({num saldo = 0, List<Map<String, dynamic>> rondas = const []}) => CuentaMesa.fromJson({
      'codigo': 'ORD1',
      'mesaCodigo': 'MES1',
      'mesaNombre': 'Mesa 1',
      'total': 30000,
      'totalPagado': 30000 - saldo,
      'saldoPendiente': saldo,
      'rondas': rondas,
    });

void main() {
  group('destino de la orden', () {
    test('se lee de la URL y vuelve a armarla', () {
      final d = DestinoOrden.deQuery({'mesa': 'MES1', 'mesaNombre': 'Terraza', 'nuevaCuenta': '1'})!;
      expect(d.nuevaCuenta, isTrue);
      expect(d.cuentaCodigo, isNull);
      final url = Uri.parse(urlTomarOrden('mi-menu', d));
      expect(url.path, '/menu/mi-menu');
      expect(url.queryParameters, {'mesa': 'MES1', 'mesaNombre': 'Terraza', 'nuevaCuenta': '1'});
      expect(DestinoOrden.deQuery({'producto': 'X'}), isNull);
    });

    test('tras enviar, las siguientes rondas van a esa cuenta y no abren otra', () {
      const d = DestinoOrden(mesaCodigo: 'MES1', mesaNombre: 'Mesa 1', nuevaCuenta: true);
      final siguiente = d.conCuenta('ORD9');
      expect(siguiente.nuevaCuenta, isFalse);
      expect(siguiente.cuentaCodigo, 'ORD9');
    });
  });

  test('mesa del mesero: bloqueo por otro y cuentas divididas', () {
    final m = MesaMesero.fromJson({
      'codigo': 'MES1',
      'nombre': 'Barra',
      'pedidosActivos': 2,
      'abiertaPorOtro': true,
      'abiertaPorMeseroNombre': 'Ana',
      'cuentasAbiertas': [{}, {}],
    });
    expect(m.abiertaPorOtro, isTrue);
    expect(m.atendidaPor, 'Ana');
    expect(m.dividida, isTrue);
  });

  test('la orden suma la misma configuración, cambia cantidades y quita', () {
    final o = UseOrdenMesero(menu: 'MEN1', destino: const DestinoOrden(mesaCodigo: 'MES1', mesaNombre: 'Mesa 1'));
    o.agregar(_item('Arepa', 5000));
    o.agregar(_item('Arepa', 5000));
    o.agregar(_item('Jugo', 4000));
    expect(o.items, hasLength(2));
    expect(o.cantidad, 3);
    expect(o.total, 14000);
    final arepa = o.items.first;
    o.cantidadDe(buildOrderItemKey(arepa), -2); // llega a 0: se quita
    expect(o.items, hasLength(1));
    o.dispose();
  });

  group('widgets', () {
    for (final ancho in [360.0, 1024.0]) {
      testWidgets('MesaCard bloqueada por otro mesero no se abre ($ancho)', (tester) async {
        var abierta = false;
        await _montar(
          tester,
          SizedBox(
            width: 180,
            height: 112,
            child: MesaCard(
              mesa: const MesaMesero(codigo: 'M', nombre: 'Mesa con nombre largo', abiertaPorOtro: true, atendidaPor: 'Ana'),
              seleccionada: false,
              onTap: () => abierta = true,
            ),
          ),
          ancho: ancho,
        );
        await tester.tap(find.text('Mesa con nombre largo'));
        expect(abierta, isFalse);
        expect(find.text('Ana'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('MesaCard libre se abre y muestra sus órdenes', (tester) async {
      var abierta = false;
      await _montar(
        tester,
        SizedBox(
          width: 180,
          height: 112,
          child: MesaCard(
            mesa: const MesaMesero(codigo: 'M', nombre: 'Mesa 2', pedidosActivos: 3, capacidad: 4),
            seleccionada: false,
            onTap: () => abierta = true,
          ),
        ),
      );
      expect(find.text('3 ordenes'), findsOneWidget);
      await tester.tap(find.text('Mesa 2'));
      expect(abierta, isTrue);
    });

    testWidgets('RondaCard pendiente: preparar y cancelar', (tester) async {
      String? estado;
      var cancelada = false;
      await _montar(
        tester,
        RondaCard(
          ronda: RondaCuenta.fromJson({
            'codigo': 'R1',
            'estado': 'pendiente',
            'total': 12000,
            'items': [
              {'cantidad': 2, 'prodNombre': 'Empanada', 'precioUnit': 6000},
            ],
          }),
          actualizando: null,
          onCambiarEstado: (e) => estado = e,
          onCancelar: () => cancelada = true,
        ),
      );
      expect(find.text('2× Empanada'), findsOneWidget);
      await tester.tap(find.text('En preparación'));
      expect(estado, 'en_proceso');
      await tester.tap(find.text('Cancelar'));
      expect(cancelada, isTrue);
    });

    Future<void> cabecera(WidgetTester tester, CuentaMesa cuenta, {required void Function() onCerrar, void Function()? onAbonar}) =>
        _montar(
          tester,
          CabeceraCuenta(
            mesaNombre: 'Mesa 1',
            cuentas: [cuenta],
            activa: cuenta,
            acciones: AccionesMesero('MEN1', 'MES1'),
            onElegirCuenta: (_) {},
            onCerrar: onCerrar,
            onCancelar: () {},
            onAbonar: onAbonar ?? () {},
            onAgregar: () {},
          ),
          ancho: 360,
        );

    testWidgets('no se cierra con saldo pendiente; se ofrece abonar', (tester) async {
      var cerrada = false;
      await cabecera(
        tester,
        _cuenta(saldo: 8000, rondas: [
          {'codigo': 'R1', 'estado': 'entregado', 'total': 30000},
        ]),
        onCerrar: () => cerrada = true,
      );
      await tester.tap(find.text('Cerrar'));
      expect(cerrada, isFalse);
      expect(find.text('Abonar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('con saldo en cero y sin rondas activas se puede cerrar', (tester) async {
      var cerrada = false;
      await cabecera(
        tester,
        _cuenta(rondas: [
          {'codigo': 'R1', 'estado': 'entregado', 'total': 30000},
        ]),
        onCerrar: () => cerrada = true,
      );
      await tester.tap(find.text('Cerrar'));
      expect(cerrada, isTrue);
      expect(find.text('Abonar'), findsNothing);
    });

    testWidgets('OrderSheet explica la cuenta nueva y muestra el total', (tester) async {
      final o = UseOrdenMesero(
        menu: 'MEN1',
        destino: const DestinoOrden(mesaCodigo: 'MES1', mesaNombre: 'Mesa 3', nuevaCuenta: true),
      )..agregar(_item('Bandeja', 25000));
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: OrderSheet(orden: o, theme: const MenuTheme(primary: Color(0xFF4F46E5)))),
      ));
      expect(find.text('Bandeja'), findsOneWidget);
      expect(find.textContaining('Abre una cuenta nueva y separada en Mesa 3'), findsOneWidget);
      expect(find.text(r'$25.000'), findsWidgets);
      expect(find.text('Confirmar orden'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
