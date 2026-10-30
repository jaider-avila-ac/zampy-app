import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/notifications/models/notification_model.dart';

void main() {
  test('parsea notificación paginada con códigos públicos', () {
    final notif = NotificationModel.fromJson({
      'codigo': 'Ntf123',
      'tipo': 'nueva_resena',
      'entidadTipo': 'menu',
      'entidadCodigo': 'MenuCode',
      'actorNombre': 'Ana',
      'entidadNombre': 'JORAF',
      'vistaPrevia': 'Muy rico todo',
      'leida': false,
      'creadoEn': '2026-10-27T10:00:00',
      'tiempoRelativo': 'hace 5 min',
    });

    expect(notif.codigo, 'Ntf123');
    expect(notif.tipo, 'NUEVA_RESENA');
    expect(notif.entidadCodigo, 'MenuCode');
    expect(notif.vistaPrevia, 'Muy rico todo');
    expect(notif.leida, isFalse);
  });

  test('acepta códigos legacy id/entidadId y marca leída', () {
    final original = NotificationModel.fromJson({
      'id': 7,
      'tipo': 'TRANSFERENCIA_PENDIENTE',
      'entidadId': 99,
      'leida': false,
    });

    final leida = original.copyWith(leida: true);

    expect(original.id, '7');
    expect(original.entidadId, '99');
    expect(leida.leida, isTrue);
    expect(leida.entidadCodigo, '99');
  });
}
