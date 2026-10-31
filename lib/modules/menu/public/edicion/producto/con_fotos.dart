import '../../models/public_menu_model.dart';

// Equivalente a src/modules/menu/public/edicion/producto/conFotos.js en React.

/// Si los productos de la categoría se muestran con foto (las de "solo texto" no la piden).
bool conFotos(MenuCategory? categoria) => (categoria?.tipoContenido ?? 'con_imagenes') != 'sin_imagenes';

MenuCategory? categoriaPorId(List<MenuCategory> categorias, String? id) =>
    categorias.where((c) => c.id == id).firstOrNull;
