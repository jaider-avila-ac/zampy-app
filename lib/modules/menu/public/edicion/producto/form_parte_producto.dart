import 'package:flutter/material.dart';

import '../../models/public_menu_model.dart';
import 'form_grupos.dart';
import 'form_opciones.dart';
import 'form_producto_basico.dart';
import 'form_promocion.dart';

// Equivalente a src/modules/menu/public/edicion/producto/FormParteProducto.jsx en React.

/// El formulario de una parte del producto (`seccion`: producto:parte, ver partes_producto).
class FormParteProducto extends StatelessWidget {
  const FormParteProducto({
    super.key,
    required this.seccion,
    required this.menuCodigo,
    required this.producto,
    required this.categorias,
    required this.onListo,
  });

  final String seccion;
  final String menuCodigo;
  final MenuProduct producto;
  final List<MenuCategory> categorias;
  final Future<void> Function() onListo;

  @override
  Widget build(BuildContext context) {
    final parte = seccion.split(':').last;
    return switch (parte) {
      'basico' => FormProductoBasico(menuCodigo: menuCodigo, producto: producto, categorias: categorias, onListo: onListo),
      'tamanos' || 'cantidades' || 'ingredientes' || 'adiciones' =>
        FormOpciones(key: ValueKey(parte), menuCodigo: menuCodigo, producto: producto, tipo: parte, onListo: onListo),
      'grupos' => FormGrupos(menuCodigo: menuCodigo, producto: producto, onListo: onListo),
      'promocion' => FormPromocion(menuCodigo: menuCodigo, producto: producto, onListo: onListo),
      _ => const SizedBox.shrink(),
    };
  }
}
