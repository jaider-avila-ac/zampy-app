import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/notifications/components/notification_item.dart';
import 'package:zammpy_app/modules/notifications/models/notification_model.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('invitación de colaboración muestra aceptar y rechazar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        NotificationItem(
          notif: const NotificationModel(
            codigo: 'N1',
            tipo: 'NUEVO_COLABORADOR',
            entidadCodigo: 'Menu1',
            leida: false,
            actorNombre: 'Ana',
            entidadNombre: 'JORAF',
            tiempoRelativo: 'hace 2 min',
          ),
          onMarkRead: (_) {},
          onDelete: (_) {},
          onNavigate: (_) {},
        ),
      ),
    );

    expect(find.textContaining('te invitó a colaborar'), findsOneWidget);
    expect(find.text('Aceptar'), findsOneWidget);
    expect(find.text('Rechazar'), findsOneWidget);
  });

  testWidgets('pedido del admin muestra ver pedidos y vista previa', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        NotificationItem(
          notif: const NotificationModel(
            codigo: 'N2',
            tipo: 'NUEVO_PEDIDO',
            entidadCodigo: 'Menu1',
            leida: true,
            actorNombre: 'Carlos',
            entidadNombre: 'JORAF',
            vistaPrevia: '2 productos',
            tiempoRelativo: 'hace 1 min',
          ),
          onMarkRead: (_) {},
          onDelete: (_) {},
          onNavigate: (_) {},
        ),
      ),
    );

    expect(find.textContaining('realizó un pedido'), findsOneWidget);
    expect(find.text('2 productos'), findsOneWidget);
    expect(find.text('Ver pedidos'), findsOneWidget);
  });
}
