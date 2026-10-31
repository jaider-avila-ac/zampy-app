import 'package:flutter/material.dart';

import 'edicion_menu.dart';

// Equivalente a src/modules/menu/public/edicion/Editable.jsx en React.

/// Una parte del menú que el dueño edita con solo tocarla (la portada, el logo), sin marcas: se ve igual que para el
/// cliente. Sin edición activa no agrega nada. Editando, el toque abre su formulario y no lo que haya adentro.
/// seccion: logo | portada
class Editable extends StatelessWidget {
  const Editable({super.key, required this.seccion, required this.etiqueta, required this.child});

  final String seccion;
  final String etiqueta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final edicion = EdicionMenu.of(context);
    if (edicion == null) return child;
    return Semantics(
      button: true,
      label: 'Editar $etiqueta',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => edicion.abrir(seccion),
        child: AbsorbPointer(child: child),
      ),
    );
  }
}
