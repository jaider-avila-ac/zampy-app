import 'api_client.dart';
import '../modules/explore/models/explore_models.dart';

// Equivalente a src/services/exploreService.js en React

class ExploreService {
  ExploreService._();

  static Future<ExploreFiltros> getFiltros() async {
    final data = await ApiClient.instance.get(
      '/api/v1/explore/filtros',
      auth: false,
    );
    if (data is Map<String, dynamic>) return ExploreFiltros.fromJson(data);
    if (data is Map) {
      return ExploreFiltros.fromJson(Map<String, dynamic>.from(data));
    }
    return ExploreFiltros.empty;
  }

  static Future<MenuScrollPage> getScroll({
    String? cursor,
    String? municipio,
    String? categoria,
    String? exclude,
  }) async {
    final data = await ApiClient.instance.get(
      '/api/v1/explore/scroll',
      query: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (municipio != null && municipio.isNotEmpty) 'municipio': municipio,
        if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
        if (exclude != null && exclude.isNotEmpty) 'exclude': exclude,
      },
    );
    if (data is Map<String, dynamic>) return MenuScrollPage.fromJson(data);
    if (data is Map) {
      return MenuScrollPage.fromJson(Map<String, dynamic>.from(data));
    }
    return const MenuScrollPage(items: [], hasMore: false);
  }

  static Future<ProductosPage> getProductos({
    String? municipio,
    String? categoria,
    String? q,
    required String semilla,
    String? despues,
    int limite = 30,
  }) async {
    final data = await ApiClient.instance.get(
      '/api/v1/explore/productos',
      auth: false,
      query: {
        if (municipio != null && municipio.isNotEmpty) 'municipio': municipio,
        if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
        if (q != null && q.isNotEmpty) 'q': q,
        'semilla': semilla,
        if (despues != null && despues.isNotEmpty) 'despues': despues,
        'limite': '$limite',
      },
    );
    if (data is Map<String, dynamic>) return ProductosPage.fromJson(data);
    if (data is Map) {
      return ProductosPage.fromJson(Map<String, dynamic>.from(data));
    }
    return const ProductosPage(items: []);
  }
}
