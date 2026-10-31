import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/menu/editor/mesas/mesa_model.dart';
import 'package:zammpy_app/modules/menu/editor/mesas/mesa_tile.dart';
import 'package:zammpy_app/modules/orders/components/comun/filtro_fechas.dart';
import 'package:zammpy_app/modules/orders/components/comun/resumen_ventas_card.dart';
import 'package:zammpy_app/modules/orders/components/cuentas/cuenta_tile.dart';
import 'package:zammpy_app/modules/orders/components/cuentas/vista_cuentas.dart';
import 'package:zammpy_app/modules/orders/hooks/catalogo_menu.dart';
import 'package:zammpy_app/modules/orders/hooks/use_cuentas.dart';
import 'package:zammpy_app/modules/orders/components/pedidos/pedido_tile.dart';
import 'package:zammpy_app/modules/orders/models/cuenta_mesa.dart';
import 'package:zammpy_app/modules/orders/models/pedido_negocio.dart';
import 'package:zammpy_app/modules/orders/utils/formato.dart';

// Fase 14: pedidos del negocio, cuentas de mesa y mesas.

final _pedidoJson = <String, dynamic>{
  'codigo': 'PED123456789',
  'estado': 'pendiente',
  'total': 45000,
  'valorPagado': null,
  'usrNombre': 'Laura Gómez',
  'usrTelefono': '3001234567',
  'usrDireccion': 'Calle 10 # 5-20',
  'usrDireccionReferencia': 'Casa azul',
  'repartidorCodigo': null,
  'creadoEn': '2026-10-30T14:05:00',
  'items': [
    {
      'productName': 'Hamburguesa',
      'quantity': 2,
      'size': {'label': 'Grande'},
      'extras': [
        {'label': 'Queso'},
      ],
      'grupos': [
        {
          'name': 'Salsas',
          'selectedItems': ['BBQ', 'Ajo'],
        },
      ],
      'priceBreakdown': {'unitPrice': 20000, 'subtotal': 40000},
    },
    {
      'productName': 'Papas',
      'quantity': 1,
      'priceBreakdown': {'subtotal': 5000},
    },
    {
      'productName': 'Gaseosa',
      'quantity': 1,
      'priceBreakdown': {'subtotal': 3000},
    },
  ],
};

final _cuentaJson = <String, dynamic>{
  'codigo': 'ORD123456789',
  'mesaCodigo': 'MES123456789',
  'mesaNombre': 'Mesa 4',
  'referencia': 'Juan',
  'meseroNombre': 'Pedro',
  'abiertaEn': '2026-10-30T12:00:00',
  'total': 60000,
  'totalEnCurso': 52000,
  'saldoPendiente': 8000,
  'rondas': [
    {
      'codigo': 'RON1',
      'estado': 'en_proceso',
      'total': 52000,
      'nota': 'Sin cebolla',
      'items': [
        {'cantidad': 2, 'prodNombre': 'Bandeja', 'detalle': 'Grande', 'nota': null},
      ],
    },
  ],
  'ajustes': [
    {'tipo': 'CARGO', 'valor': 8000, 'motivo': 'Servicio a domicilio', 'actorNombre': 'Ana'},
  ],
  'pagos': [
    {'tipo': 'ABONO', 'medio': 'EFECTIVO', 'valor': 52000, 'actorNombre': 'Ana'},
  ],
};

Future<void> _montar(WidgetTester tester, Widget child, {double ancho = 390}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(ancho, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('formato', () {
    test('precio con separador de miles', () {
      expect(precio(1234567), r'$1.234.567');
      expect(precio(0), r'$0');
      expect(precio(-8000), r'$-8.000');
    });

    test('bogotaHoy usa UTC−5 y no el día del dispositivo', () {
      // 03:00 UTC del 31 = 22:00 del 30 en Bogotá
      expect(bogotaHoy(DateTime.utc(2026, 10, 31, 3)), '2026-10-30');
      expect(bogotaHoy(DateTime.utc(2026, 10, 31, 6)), '2026-10-31');
    });
  });

  group('modelos', () {
    test('pedido del negocio por código, con ítems y opciones', () {
      final p = PedidoNegocio.fromJson(_pedidoJson);
      expect(p.codigo, 'PED123456789');
      expect(p.tieneAcciones, isTrue);
      expect(p.items, hasLength(3));
      expect(p.items.first.tamano, 'Grande');
      expect(p.items.first.adiciones, ['Queso']);
      expect(p.items.first.grupos.single, ('Salsas', 'BBQ, Ajo'));
      expect(resumenItems(p.items), '2× Hamburguesa, 1× Papas');
    });

    test('ítems guardados como JSON en texto (pedidos antiguos)', () {
      final items = itemsDePedido('[{"productName":"Arepa","quantity":3}]');
      expect(items.single.nombre, 'Arepa');
      expect(items.single.cantidad, 3);
      expect(itemsDePedido('no es json'), isEmpty);
    });

    test('asignar repartidor conserva el resto del pedido', () {
      final p = PedidoNegocio.fromJson(_pedidoJson).copyWith(repartidorCodigo: 'USR1', repartidorNombre: 'Carlos');
      expect(p.repartidorNombre, 'Carlos');
      expect(p.clienteNombre, 'Laura Gómez');
    });

    test('cuenta de mesa con rondas, ajustes y pagos', () {
      final c = CuentaMesa.fromJson(_cuentaJson);
      expect(c.codigo, 'ORD123456789');
      expect(c.mesaCodigo, 'MES123456789');
      expect(c.conSaldo, isTrue);
      expect(c.rondas.single.items.single.nombre, 'Bandeja');
      expect(c.ajustes.single.esCargo, isTrue);
      expect(c.pagos.single.esAbono, isTrue);
    });

    test('mesa: ocupada con pedidos activos', () {
      final m = Mesa.fromJson({
        'codigo': 'MES1',
        'nombre': 'Terraza',
        'capacidad': 4,
        'activo': true,
        'pedidosActivos': 2,
      });
      expect(m.ocupada, isTrue);
      expect(m.capacidad, 4);
    });
  });

  group('widgets', () {
    for (final ancho in [360.0, 1024.0]) {
      testWidgets('PedidoTile pendiente muestra Preparar y Cancelar sin desbordes ($ancho)', (tester) async {
        String? cambio;
        await _montar(
          tester,
          PedidoTile(
            pedido: PedidoNegocio.fromJson(_pedidoJson),
            actualizando: null,
            repartidores: const [Repartidor('USR1', 'Carlos')],
            onCambiarEstado: (e) => cambio = e,
            onValorPagado: (_) {},
            onAsignarRepartidor: (_) {},
          ),
          ancho: ancho,
        );
        expect(find.text('Preparar'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
        expect(find.text('Entregado'), findsNothing);
        await tester.tap(find.text('Preparar'));
        expect(cambio, 'en_proceso');

        // al desplegarlo se ven las opciones, la dirección y el repartidor
        await tester.tap(find.text('Laura Gómez'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Grande'), findsOneWidget);
        expect(find.textContaining('Casa azul'), findsOneWidget);
        expect(find.text('Sin asignar'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('PedidoTile entregado ofrece registrar el pago', (tester) async {
      await _montar(
        tester,
        PedidoTile(
          pedido: PedidoNegocio.fromJson({..._pedidoJson, 'estado': 'entregado'}),
          actualizando: null,
          repartidores: const [],
          onCambiarEstado: (_) {},
          onValorPagado: (_) {},
          onAsignarRepartidor: (_) {},
        ),
      );
      expect(find.text('Registrar pago'), findsOneWidget);
      expect(find.text('Preparar'), findsNothing);
    });

    testWidgets('CuentaTile en curso despliega detalle y acciones', (tester) async {
      await _montar(
        tester,
        CuentaTile(
          cuenta: CuentaMesa.fromJson(_cuentaJson),
          enCurso: true,
          menu: 'MEN1',
          onAgregarItem: () {},
          onAjustar: () {},
          onPago: () {},
          onCambiada: () {},
        ),
      );
      expect(find.textContaining('Mesa 4'), findsOneWidget);
      expect(find.text(r'$52.000'), findsOneWidget); // total en curso
      await tester.tap(find.textContaining('Mesa 4'));
      await tester.pumpAndSettle();
      expect(find.text('Nota: Sin cebolla'), findsOneWidget);
      expect(find.text('Agregar ítem olvidado'), findsOneWidget);
      expect(find.text('Conciliar saldo'), findsOneWidget);
      expect(find.text('Cerrar cuenta'), findsOneWidget);
      expect(find.text('Cancelar (ignorar todo)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CuentaTile cerrada no permite cerrar ni agregar ítems', (tester) async {
      await _montar(
        tester,
        CuentaTile(
          cuenta: CuentaMesa.fromJson({..._cuentaJson, 'saldoPendiente': 0}),
          enCurso: false,
          menu: 'MEN1',
          onAgregarItem: () {},
          onAjustar: () {},
          onPago: () {},
          onCambiada: () {},
        ),
      );
      await tester.tap(find.textContaining('Mesa 4'));
      await tester.pumpAndSettle();
      expect(find.text('Registrar ajuste auditado'), findsOneWidget);
      expect(find.text('Cerrar cuenta'), findsNothing);
      expect(find.text('Agregar ítem olvidado'), findsNothing);
      expect(find.text('Conciliar saldo'), findsNothing);
    });

    for (final ancho in [360.0, 1024.0]) {
      testWidgets('MesaTile ocupada no se puede eliminar ($ancho)', (tester) async {
        var eliminada = false;
        await _montar(
          tester,
          MesaTile(
            mesa: const Mesa(codigo: 'MES1', nombre: 'Terraza VIP', activo: true, capacidad: 6, pedidosActivos: 1),
            onEditar: () {},
            onAlternar: () {},
            onEliminar: () => eliminada = true,
          ),
          ancho: ancho,
        );
        await tester.tap(find.byTooltip('Tiene pedidos activos'));
        expect(eliminada, isFalse);
        expect(find.text('Terraza VIP'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('resumen y filtro caben en un teléfono estrecho', (tester) async {
      await _montar(
        tester,
        Column(children: [
          const ResumenVentasCard(
            resumen: ResumenVentas(totalVentas: 123456789, totalPedidos: 98765432, totalCuentas: 24691357),
            cargando: false,
          ),
          FiltroFechas(desde: '2026-10-01', hasta: '2026-10-30', onDesde: (_) {}, onHasta: (_) {}, onBuscar: () {}),
        ]),
        ancho: 320,
      );
      expect(find.text(r'$123.456.789'), findsOneWidget);
      expect(find.text('30 oct 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('VistaCuentas pinta totales y la lista de cuentas', (tester) async {
      final cuentas = _CuentasFalsas([CuentaMesa.fromJson(_cuentaJson)], 52000);
      await _montar(tester, VistaCuentas(cuentas: cuentas, menu: 'MEN1', catalogo: CatalogoMenu('MEN1')));
      // el modo (en curso / cerradas) sale del tipo de estado: un estado que no es UseCuentasEnCurso es de cerradas
      expect(find.text('CUENTAS CERRADAS'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.textContaining('Mesa 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _CuentasFalsas extends ChangeNotifier implements CuentasVista {
  _CuentasFalsas(this.items, this.total);

  @override
  final List<CuentaMesa> items;
  @override
  final num total;
  @override
  bool get cargando => false;
  @override
  String? get error => null;
  @override
  Future<void> recargar({bool silencioso = false}) async {}
}
