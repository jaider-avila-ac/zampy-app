import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';
import 'invitacion_model.dart';

class InvitacionService {
  InvitacionService._();

  static Future<InvitacionEstado?> getEstado() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;
      final res = await http
          .get(
            Uri.parse('$kApiBase/api/invitaciones/estado'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      return InvitacionEstado.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> toggleActivo() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;
      final res = await http
          .put(
            Uri.parse('$kApiBase/api/invitaciones/toggle'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['invActivo'] as bool?;
    } catch (_) {
      return null;
    }
  }
}
