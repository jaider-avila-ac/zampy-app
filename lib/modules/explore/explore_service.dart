import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';
import 'models/menu_feed_item.dart';

/// Equivalente a exploreService.js + publicApiService.js + interaccionService.js
/// (solo las operaciones de exploración).
class ExploreService {
  ExploreService._();

  // ── Feed principal ─────────────────────────────────────────────────────────
  /// GET /api/explore/feed[?ciudad=...]
  static Future<ExploreFeed> getFeed({String? ciudad}) async {
    try {
      final qs = ciudad != null
          ? '?ciudad=${Uri.encodeComponent(ciudad)}'
          : '';
      final res = await http
          .get(Uri.parse('$kApiBase/api/explore/feed$qs'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return ExploreFeed.empty;
      }
      return ExploreFeed.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return ExploreFeed.empty;
    }
  }

  // ── Paginación infinita ────────────────────────────────────────────────────
  /// GET /api/explore/menus?offset=...&size=...
  static Future<List<MenuFeedItem>> getMenusPaged(int offset,
      {int size = 24}) async {
    try {
      final res = await http
          .get(Uri.parse(
              '$kApiBase/api/explore/menus?offset=$offset&size=$size'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) return [];
      final list = jsonDecode(res.body) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(MenuFeedItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Búsqueda pública ───────────────────────────────────────────────────────
  /// GET /api/public/menus?search=...
  static Future<List<MenuFeedItem>> buscarMenus(String search) async {
    try {
      final qs = 'search=${Uri.encodeComponent(search.trim())}';
      final res = await http
          .get(Uri.parse('$kApiBase/api/public/menus?$qs'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) return [];
      final list = jsonDecode(res.body) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(MenuFeedItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Mis encantados (requiere auth) ─────────────────────────────────────────
  /// GET /api/interacciones/mis-encantados → `List<int>` de menId
  static Future<Set<int>> misEncantados() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {};
      final res = await http
          .get(
            Uri.parse('$kApiBase/api/interacciones/mis-encantados'),
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
}
