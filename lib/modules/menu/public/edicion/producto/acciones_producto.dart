import 'package:flutter/material.dart';

import '../../../../../services/live_editor_service.dart';
import '../../models/public_menu_model.dart';
import '../comun/guardar.dart';
import '../edicion_menu.dart';
import 'partes_producto.dart';

// Equivalente a src/modules/menu/public/edicion/producto/useAccionesProducto.js en React.

/// Una opción del "⋯" de un producto.
class OpcionProductoMenu {
  const OpcionProductoMenu({required this.icono, required this.texto, required this.accion, this.peligro = false, this.separado = false});
  final IconData icono;
  final String texto;
  final Future<void> Function() accion;
  final bool peligro;
  final bool separado;
}

/// Las opciones del "⋯" de un producto: cada parte abre su propio formulario, y mostrar en Explorar, ocultar y
/// eliminar se aplican de una vez y recargan el menú.
List<OpcionProductoMenu> accionesProducto(
  BuildContext context,
  MenuProduct producto,
  EdicionMenu edicion, {
  required ValueChanged<bool> onOcupado,
}) {
  final codigo = edicion.menuCodigo;

  Future<void> ahora(Future<void> Function() fn, String mensaje) async {
    onOcupado(true);
    try {
      await fn();
      if (context.mounted) avisar(context, mensaje);
      await edicion.recargar();
    } catch (e) {
      if (context.mounted) avisar(context, 'No se pudo guardar: ${mensajeError(e)}', error: true);
    } finally {
      onOcupado(false);
    }
  }

  Future<void> eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${producto.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) await ahora(() => LiveEditorService.deleteProduct(codigo, producto.id), 'Producto eliminado');
  }

  final oculto = !producto.isVisible;
  return [
    for (final p in partesProducto)
      OpcionProductoMenu(icono: p.icono, texto: p.texto, accion: () async => edicion.abrir(p.seccion, producto)),
    OpcionProductoMenu(
      icono: Icons.explore_outlined,
      texto: producto.enExplorar ? 'Quitar de Explorar' : 'Mostrar en Explorar',
      separado: true,
      accion: () => ahora(
        () => LiveEditorService.productExplore(codigo, producto.id, !producto.enExplorar),
        producto.enExplorar ? 'Ya no aparece en Explorar' : 'Ahora aparece en Explorar',
      ),
    ),
    OpcionProductoMenu(
      icono: oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      texto: oculto ? 'Mostrar en el menú' : 'Ocultar del menú',
      accion: () => ahora(
        () => LiveEditorService.updateProductBasic(codigo, producto.id, {'isVisible': oculto}),
        oculto ? 'Producto visible' : 'Producto oculto',
      ),
    ),
    OpcionProductoMenu(icono: Icons.delete_outline, texto: 'Eliminar', peligro: true, accion: eliminar),
  ];
}
