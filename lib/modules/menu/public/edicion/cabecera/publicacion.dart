import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../services/live_editor_service.dart';
import '../comun/guardar.dart';

// Equivalente a src/modules/menu/public/edicion/hooks/usePublicacion.js en React.

/// Publicar el menú. La primera publicación puede pedir prueba gratis, plan o cupón: si falla, se lleva a
/// "Plan y visibilidad". Devuelve true si se publicó.
Future<bool> publicarMenu(BuildContext context, String menuCodigo) async {
  try {
    await LiveEditorService.publish(menuCodigo);
    if (context.mounted) avisar(context, '¡Menú publicado! Ya está visible para tus clientes.');
    return true;
  } catch (e) {
    if (context.mounted) {
      avisar(context, 'Falta un paso para publicar: ${mensajeError(e)}', error: true);
      context.push('/menus/$menuCodigo/edit?tab=publish');
    }
    return false;
  }
}

/// Despublicar el menú, con confirmación. Devuelve true si se despublicó.
Future<bool> despublicarMenu(BuildContext context, String menuCodigo) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Despublicar el menú'),
      content: const Text('Dejará de estar visible para tus clientes hasta que lo publiques de nuevo.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Despublicar')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  try {
    await LiveEditorService.unpublish(menuCodigo);
    if (context.mounted) avisar(context, 'Menú despublicado. Ya no está visible para el público.');
    return true;
  } catch (e) {
    if (context.mounted) avisar(context, 'No se pudo despublicar: ${mensajeError(e)}', error: true);
    return false;
  }
}
