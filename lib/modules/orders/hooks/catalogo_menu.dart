import '../../../services/api_client.dart';
import '../../menu/public/models/public_menu_model.dart';

/// Los productos y grupos PUBLICADOS del menú, para agregar ítems a una cuenta (como menu.published en React). Se
/// carga una vez por pantalla, al abrir "Agregar ítem olvidado". Sin versión publicada no hay catálogo (null).
class CatalogoMenu {
  CatalogoMenu(this.menu);

  final String menu;
  Future<PublicMenuData?>? _carga;

  Future<PublicMenuData?> cargar() => _carga ??= _pedir().catchError((Object e) {
        _carga = null; // un fallo no queda guardado: el siguiente intento vuelve a pedirlo
        throw e;
      });

  Future<PublicMenuData?> _pedir() async {
    final data = await ApiClient.instance.get('/api/v1/menus/$menu');
    if (data is! Map || data['published'] is! Map) return null;
    return PublicMenuData.fromRoot(Map<String, dynamic>.from(data));
  }
}
