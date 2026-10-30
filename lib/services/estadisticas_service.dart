import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api.dart';

// Equivalente a src/services/estadisticasService.js — tracking de vistas

class EstadisticasService {
  EstadisticasService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _viewerKey = '_vt';

  static Future<String> _viewerToken() async {
    try {
      final existing = await _storage.read(key: _viewerKey);
      if (existing != null && existing.isNotEmpty) return existing;

      final random = Random.secure();
      final token = List.generate(
        32,
        (_) => '0123456789abcdef'[random.nextInt(16)],
      ).join();
      await _storage.write(key: _viewerKey, value: token);
      return token;
    } catch (_) {
      return 'anonymous';
    }
  }

  static Future<void> registrarVistaMenu(String slug) async {
    try {
      final token = await _viewerToken();
      await http
          .post(
            Uri.parse('$kApiBase/api/v1/public/menu/$slug/vista'),
            headers: {'X-Viewer-Token': token},
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static Future<void> registrarVistaProducto(
    String slug,
    String productId,
  ) async {
    try {
      final token = await _viewerToken();
      await http
          .post(
            Uri.parse(
              '$kApiBase/api/v1/public/menu/$slug/producto/$productId/vista',
            ),
            headers: {'X-Viewer-Token': token},
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getResumen(String menuId) async {
    try {
      final raw = await _storage.read(key: 'auth');
      final token = raw == null
          ? null
          : (jsonDecode(raw) as Map<String, dynamic>)['token'] as String?;
      final res = await http
          .get(
            Uri.parse('$kApiBase/api/v1/menus/$menuId/estadisticas'),
            headers: token == null ? {} : {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
