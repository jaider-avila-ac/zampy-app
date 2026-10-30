import 'dart:io';

import '../../../services/api_client.dart';
import '../../../services/image_upload_service.dart';
import '../../../services/menu_editor_service.dart';
import '../modules/menu/editor/live/editor_models.dart';

class LiveEditorService {
  LiveEditorService._();

  static Future<LiveMenu> load(String codigo) async {
    final data = await ApiClient.instance.get('/api/v1/menus/$codigo');
    return LiveMenu.fromJson(Map<String, dynamic>.from(data as Map));
  }

  static Future<LiveMenu> saveSection(
    String codigo,
    String seccion,
    Map<String, dynamic> body,
  ) async {
    final data = await ApiClient.instance.patch(
      '/api/v1/menus/$codigo/secciones/$seccion',
      body: body,
    );
    return LiveMenu.fromJson(Map<String, dynamic>.from(data as Map));
  }

  static Future<void> saveHorario(
    String codigo,
    Map<String, dynamic> horario,
  ) async {
    await ApiClient.instance.put(
      '/api/v1/menus/$codigo/horario',
      body: horario,
    );
  }

  static Future<String> upload(String codigo, String tipo, File file) =>
      ImageUploadService.upload(file, 'menus/$codigo/$tipo');

  static Future<LiveCategory> createCategory(
    String codigo,
    Map<String, dynamic> body,
  ) async {
    final data = await ApiClient.instance.post(
      '/api/v1/menus/$codigo/categorias',
      body: body,
    );
    return LiveCategory.fromJson(Map<String, dynamic>.from(data as Map));
  }

  static Future<void> updateCategory(
    String codigo,
    String catCodigo,
    Map<String, dynamic> body,
  ) async {
    await ApiClient.instance.put(
      '/api/v1/menus/$codigo/categorias/$catCodigo',
      body: body,
    );
  }

  static Future<void> deleteCategory(String codigo, String catCodigo) async {
    await ApiClient.instance.delete(
      '/api/v1/menus/$codigo/categorias/$catCodigo',
    );
  }

  static Future<void> orderCategories(String codigo, List<String> ids) async {
    await ApiClient.instance.patch(
      '/api/v1/menus/$codigo/categorias/orden',
      body: [
        for (var i = 0; i < ids.length; i++) {'id': ids[i], 'order': i},
      ],
    );
  }

  static Future<LiveProduct> createProduct(
    String codigo,
    Map<String, dynamic> body,
  ) async {
    final data = await ApiClient.instance.post(
      '/api/v1/menus/$codigo/productos',
      body: body,
    );
    return LiveProduct.fromJson(Map<String, dynamic>.from(data as Map));
  }

  static Future<void> updateProductBasic(
    String codigo,
    String prodCodigo,
    Map<String, dynamic> body,
  ) async {
    await ApiClient.instance.patch(
      '/api/v1/menus/$codigo/productos/$prodCodigo',
      body: body,
    );
  }

  static Future<void> updateProductPart(
    String codigo,
    String prodCodigo,
    String parte,
    Object body,
  ) async {
    await ApiClient.instance.put(
      '/api/v1/menus/$codigo/productos/$prodCodigo/$parte',
      body: body,
    );
  }

  static Future<void> deleteProduct(String codigo, String prodCodigo) async {
    await ApiClient.instance.delete(
      '/api/v1/menus/$codigo/productos/$prodCodigo',
    );
  }

  static Future<void> productExplore(
    String codigo,
    String prodCodigo,
    bool enExplorar,
  ) async {
    await ApiClient.instance.patch(
      '/api/v1/menus/$codigo/productos/$prodCodigo/explorar',
      body: {'enExplorar': enExplorar},
    );
  }

  static Future<LiveGroup> createGroup(
    String codigo,
    Map<String, dynamic> body,
  ) async {
    final data = await ApiClient.instance.post(
      '/api/v1/menus/$codigo/grupos',
      body: body,
    );
    return LiveGroup.fromJson(Map<String, dynamic>.from(data as Map));
  }

  static Future<void> updateGroup(
    String codigo,
    String grupoCodigo,
    Map<String, dynamic> body,
  ) async {
    await ApiClient.instance.put(
      '/api/v1/menus/$codigo/grupos/$grupoCodigo',
      body: body,
    );
  }

  static Future<void> deleteGroup(String codigo, String grupoCodigo) async {
    await ApiClient.instance.delete(
      '/api/v1/menus/$codigo/grupos/$grupoCodigo',
    );
  }

  static Future<void> publish(String codigo, {bool trial = false}) async {
    await ApiClient.instance.post(
      '/api/v1/menus/$codigo/publish',
      query: {if (trial) 'trial': 'true'},
    );
  }

  static Future<void> unpublish(String codigo) async {
    await ApiClient.instance.post('/api/v1/menus/$codigo/unpublish');
  }

  static Future<int> applyCoupon(String codigo, String cupon) async {
    final data = await ApiClient.instance.post(
      '/api/v1/suscripciones/menus/$codigo/cupon',
      body: {'codigo': cupon},
    );
    if (data is Map) return (data['dias'] as num?)?.toInt() ?? 0;
    return 0;
  }

  static Future<bool> checkSlug(String slug, {String? excludeCodigo}) =>
      MenuEditorService.checkSlugCode(slug, excludeCodigo: excludeCodigo);
}
