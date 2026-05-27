import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';
import 'logro_model.dart';

/// Equivalente a logroService.js (solo la parte del usuario normal).
class LogroService {
  LogroService._();

  /// GET /api/logros — progreso del usuario autenticado.
  static Future<List<Logro>> miProgreso() async {
    try {
      final token = await AuthService.getToken();
      final res = await http
          .get(
            Uri.parse('$kApiBase/api/logros'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(Logro.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// GET /api/menus — devuelve los menús del usuario.
  /// Se usa para saber si tiene al menos uno (para mostrar Logros en el drawer).
  static Future<bool> tieneMenus() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;
      final res = await http
          .get(
            Uri.parse('$kApiBase/api/menus'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return false;
      final list = jsonDecode(res.body);
      return list is List && list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
