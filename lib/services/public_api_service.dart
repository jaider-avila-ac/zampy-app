import 'api_client.dart';
import '../modules/explore/models/explore_models.dart';
import '../modules/menu/create/models/create_menu_models.dart';

// Equivalente a src/services/publicApiService.js en React

class PublicApiService {
  PublicApiService._();

  static Future<List<TarjetaMenu>> buscarMenus({
    String search = '',
    String categoria = '',
    String municipio = '',
  }) async {
    final data = await ApiClient.instance.get(
      '/api/v1/public/menus',
      auth: false,
      query: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (categoria.isNotEmpty) 'categoria': categoria,
        if (municipio.isNotEmpty) 'municipio': municipio,
      },
    );

    final list = data is List ? data : const [];
    return list
        .whereType<Map>()
        .map((item) => TarjetaMenu.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<List<CategoriaRestaurante>> listarCategorias() async {
    final data = await ApiClient.instance.get(
      '/api/v1/public/categorias',
      auth: false,
    );
    final list = data is List ? data : const [];
    return list
        .whereType<Map>()
        .map(
          (item) =>
              CategoriaRestaurante.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((cat) => cat.codigo.isNotEmpty)
        .toList();
  }
}
