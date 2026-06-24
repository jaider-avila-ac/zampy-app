import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

// Equivalente a src/services/logroService.js → logroService.miProgreso

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class LogroService {
  LogroService._();

  // GET /api/v1/logros
  static Future<List<dynamic>> miProgreso() async {
    try {
      final raw   = await _storage.read(key: 'auth');
      final token = raw != null
          ? (jsonDecode(raw) as Map<String, dynamic>)['token'] as String?
          : null;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final res = await http
          .get(Uri.parse('$kApiBase/api/v1/logros'), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      return jsonDecode(res.body) as List;
    } catch (_) {
      return [];
    }
  }
}
