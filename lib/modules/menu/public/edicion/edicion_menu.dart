import 'package:flutter/widgets.dart';

// Equivalente a src/modules/menu/public/edicion/contexto.js + EdicionMenuProvider.jsx en React.
// Edición en el propio menú: cuando el dueño (o un editor) ve su menú, cada parte se puede tocar para cambiar solo
// esa parte (logo, portada, información, categorías, cada producto). Fuera de este modo los componentes se ven igual
// que siempre (EdicionMenu.of devuelve null).

/// Abre una sección del panel de edición; [datos] acompaña a la sección (p. ej. el producto de "producto:tamanos").
typedef AbrirSeccion = void Function(String seccion, [Object? datos]);

class EdicionMenu extends InheritedWidget {
  const EdicionMenu({
    super.key,
    required this.abrir,
    required this.menuCodigo,
    required this.recargar,
    this.encabezado,
    required super.child,
  });

  final AbrirSeccion abrir;

  /// Código del menú: para las acciones que guardan de una vez (ocultar, mostrar en Explorar, eliminar).
  final String menuCodigo;

  /// Vuelve a pedir el contenido del menú.
  final Future<void> Function() recargar;

  /// Lo que el dueño ve de más en la cabecera del menú (el menú hamburguesa de edición).
  final Widget? encabezado;

  /// La edición activa, o null si el menú se ve como cliente.
  static EdicionMenu? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<EdicionMenu>();

  @override
  bool updateShouldNotify(EdicionMenu old) =>
      menuCodigo != old.menuCodigo || encabezado != old.encabezado || abrir != old.abrir;
}
