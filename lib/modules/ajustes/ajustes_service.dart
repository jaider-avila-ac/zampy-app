import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';
import 'dispositivo_model.dart';

class AjustesService {
  AjustesService._();

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Dispositivo>> getDispositivos() async {
    try {
      final res = await http
          .get(Uri.parse('$kApiBase/api/dispositivos'),
              headers: await _headers())
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list.whereType<Map<String, dynamic>>().map(Dispositivo.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> revocarDispositivo(int id) async {
    try {
      final res = await http
          .delete(Uri.parse('$kApiBase/api/dispositivos/$id'),
              headers: await _headers())
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getCodigoInv() async {
    try {
      final res = await http
          .get(Uri.parse('$kApiBase/api/user/me'),
              headers: await _headers())
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['codigoInv'] as String?;
    } catch (_) {
      return null;
    }
  }
}
