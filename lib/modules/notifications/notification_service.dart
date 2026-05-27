import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';
import 'models/notification_item.dart';

/// Equivalente a los métodos de notificación en interaccionService.js.
class NotificationService {
  NotificationService._();

  // ── Headers con JWT ────────────────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Listado completo ───────────────────────────────────────────────────────
  /// GET /api/notificaciones
  static Future<List<NotificationItem>> getNotificaciones() async {
    try {
      final res = await http
          .get(
            Uri.parse('$kApiBase/api/notificaciones'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Sin leer ───────────────────────────────────────────────────────────────
  /// GET /api/notificaciones/sin-leer → { count: N }
  static Future<int> getSinLeer() async {
    try {
      final res = await http
          .get(
            Uri.parse('$kApiBase/api/notificaciones/sin-leer'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return 0;
      final data = jsonDecode(res.body);
      if (data is Map) return (data['count'] as num?)?.toInt() ?? 0;
      if (data is num) return data.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ── Marcar una como leída ──────────────────────────────────────────────────
  /// PUT /api/notificaciones/{id}/leida
  static Future<void> marcarLeida(int id) async {
    try {
      await http
          .put(
            Uri.parse('$kApiBase/api/notificaciones/$id/leida'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ── Marcar todas como leídas ───────────────────────────────────────────────
  /// PUT /api/notificaciones/leer-todas
  static Future<void> marcarTodasLeidas() async {
    try {
      await http
          .put(
            Uri.parse('$kApiBase/api/notificaciones/leer-todas'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ── Eliminar ───────────────────────────────────────────────────────────────
  /// DELETE /api/notificaciones/{id}
  static Future<void> eliminar(int id) async {
    try {
      await http
          .delete(
            Uri.parse('$kApiBase/api/notificaciones/$id'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
