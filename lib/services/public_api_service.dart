import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

// Equivalente a src/services/publicApiService.js en React

class PublicApiService {
  PublicApiService._();

  // GET /api/v1/public/menus?search=...
  static Future<List<dynamic>> buscarMenus(String search) async {
    try {
      final params = <String, String>{};
      if (search.trim().isNotEmpty) params['search'] = search.trim();
      final uri = Uri.parse('$kApiBase/api/v1/public/menus')
          .replace(queryParameters: params.isEmpty ? null : params);
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) return [];
      return jsonDecode(res.body) as List;
    } catch (_) {
      return [];
    }
  }
}
