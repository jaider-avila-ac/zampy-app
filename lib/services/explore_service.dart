import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

// Equivalente a src/services/exploreService.js en React

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

Future<String?> _getToken() async {
  try {
    final raw = await _storage.read(key: 'auth');
    if (raw == null) return null;
    return (jsonDecode(raw) as Map<String, dynamic>)['token'] as String?;
  } catch (_) {
    return null;
  }
}

class ExploreService {
  ExploreService._();

  // GET /api/v1/explore/feed?ciudad=...
  static Future<Map<String, dynamic>> getFeed({String? ciudad}) async {
    try {
      final qs = ciudad != null ? '?ciudad=${Uri.encodeComponent(ciudad)}' : '';
      final res = await http
          .get(Uri.parse('$kApiBase/api/v1/explore/feed$qs'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) return _emptyFeed;
      return (jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return _emptyFeed;
    }
  }

  // GET /api/v1/explore/scroll?cursor=...&ciudad=...&exclude=...
  static Future<Map<String, dynamic>?> getScroll({
    String? cursor,
    String? ciudad,
    String? exclude,
  }) async {
    try {
      final token = await _getToken();
      final params = <String, String>{};
      if (cursor  != null) params['cursor']  = cursor;
      if (ciudad  != null) params['ciudad']  = ciudad;
      if (exclude != null) params['exclude'] = exclude;
      final uri = Uri.parse('$kApiBase/api/v1/explore/scroll').replace(queryParameters: params.isEmpty ? null : params);
      final res = await http
          .get(uri, headers: token != null ? {'Authorization': 'Bearer $token'} : {})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // GET /api/v1/interacciones/mis-encantados — requiere auth
  static Future<Set<int>> misEncantados() async {
    try {
      final token = await _getToken();
      if (token == null) return {};
      final res = await http
          .get(
            Uri.parse('$kApiBase/api/v1/interacciones/mis-encantados'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return {};
      final list = jsonDecode(res.body) as List;
      return list.map((e) => (e as num).toInt()).toSet();
    } catch (_) {
      return {};
    }
  }

  // PUT /api/v1/user/me/location — requiere auth
  static Future<void> saveLocation(double lat, double lon, String? ciudad) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      await http
          .put(
            Uri.parse('$kApiBase/api/v1/user/me/location'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({'lat': lat, 'lon': lon, 'ciudad': ciudad}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static const _emptyFeed = {
    'nearby': [],
    'trending': [],
    'nuevo': [],
    'todos': [],
  };
}
