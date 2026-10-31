import 'package:flutter/material.dart';

import '../../../../../shared/app_colors.dart';
import '../../../../../shared/responsive.dart';
import '../../models/public_menu_model.dart';
import '../categorias/form_categorias.dart';
import '../negocio/form_imagen.dart';
import '../negocio/form_informacion.dart';
import '../producto/form_nuevo_producto.dart';
import '../producto/form_parte_producto.dart';
import '../tema/form_tema.dart';
import '../tema/tema_elegido.dart';
import 'secciones.dart';

// Equivalente a src/modules/menu/public/edicion/panel/PanelEdicion.jsx en React.

/// Lo que necesita el panel para abrir el tema (ver FormTema).
class TemaPanel {
  const TemaPanel({required this.actual, required this.guardado, required this.onElegir});
  final TemaElegido actual;
  final TemaElegido guardado;
  final ValueChanged<TemaElegido> onElegir;
}

/// Edición en el propio menú: un formulario por sección (solo esa parte, guardada con su propio endpoint y aplicada de
/// inmediato). Se abre desde el menú de la cabecera, la portada, el logo y el "⋯" de cada producto. En teléfono es una
/// hoja inferior; en tablet, un diálogo de ancho limitado.
/// onRecargar: vuelve a pedir el menú. Al guardar una sección se recarga y se cierra el panel.
Future<void> abrirPanelEdicion(
  BuildContext context, {
  required String seccion,
  Object? datos,
  required String menuCodigo,
  required PublicMenuData menu,
  required Future<void> Function() onRecargar,
  required TemaPanel tema,
}) {
  Widget contenido(BuildContext ctx) {
    Future<void> listo() async {
      await onRecargar();
      if (ctx.mounted) Navigator.of(ctx).pop();
    }

    return _FormularioSeccion(
      seccion: seccion,
      datos: datos,
      menuCodigo: menuCodigo,
      menu: menu,
      onListo: listo,
      onRecargar: onRecargar,
      onCerrar: () => Navigator.of(ctx).pop(),
      tema: tema,
    );
  }

  final titulo = tituloSeccion(seccion, datos);
  if (esTablet(context)) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600, maxHeight: MediaQuery.sizeOf(ctx).height * 0.85),
          child: _Marco(titulo: titulo, child: contenido(ctx)),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
        child: _Marco(titulo: titulo, child: contenido(ctx)),
      ),
    ),
  );
}

class _Marco extends StatelessWidget {
  const _Marco({required this.titulo, required this.child});
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.kTextPrimary)),
                ),
                IconButton(tooltip: 'Cerrar', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), child: child),
          ),
        ],
      );
}

class _FormularioSeccion extends StatelessWidget {
  const _FormularioSeccion({
    required this.seccion,
    required this.datos,
    required this.menuCodigo,
    required this.menu,
    required this.onListo,
    required this.onRecargar,
    required this.onCerrar,
    required this.tema,
  });

  final String seccion;
  final Object? datos;
  final String menuCodigo;
  final PublicMenuData menu;
  final Future<void> Function() onListo;
  final Future<void> Function() onRecargar;
  final VoidCallback onCerrar;
  final TemaPanel tema;

  @override
  Widget build(BuildContext context) {
    if (seccion.startsWith('producto:') && datos is MenuProduct) {
      return FormParteProducto(
        seccion: seccion,
        menuCodigo: menuCodigo,
        producto: datos! as MenuProduct,
        categorias: menu.categories,
        onListo: onListo,
      );
    }
    return switch (seccion) {
      'logo' || 'portada' => FormImagen(
          key: ValueKey(seccion),
          menuCodigo: menuCodigo,
          seccion: seccion,
          valor: seccion == 'logo' ? menu.info.logoUrl : menu.info.bannerUrl,
          onListo: onListo,
        ),
      'informacion' => FormInformacion(
          menuCodigo: menuCodigo,
          info: menu.info,
          categoriaCodigo: menu.categoriaCodigo,
          onListo: onListo,
        ),
      'categorias' => FormCategorias(menuCodigo: menuCodigo, onCambio: onRecargar),
      'tema' => FormTema(actual: tema.actual, guardado: tema.guardado, onElegir: tema.onElegir, onCerrar: onCerrar),
      'producto-nuevo' => FormNuevoProducto(
          menuCodigo: menuCodigo,
          categorias: menu.categories,
          categoriaInicial: datos is String ? datos as String : null,
          onListo: onListo,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
