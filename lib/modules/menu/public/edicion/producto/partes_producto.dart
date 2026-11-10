import 'package:flutter/material.dart';

import '../../models/public_menu_model.dart';

// Equivalente a src/modules/menu/public/edicion/producto/partesProducto.js en React.
// Las partes de un producto que se editan una a una (cada una con su formulario y su endpoint).

class ParteProducto {
  const ParteProducto(this.seccion, this.texto, this.titulo, this.icono);
  final String seccion;
  final String texto;
  final String titulo;
  final IconData icono;
}

const partesProducto = [
  ParteProducto('producto:basico', 'Editar datos', 'Editar producto', Icons.edit_outlined),
  ParteProducto('producto:tamanos', 'Tamaños', 'Tamaños', Icons.straighten),
  ParteProducto('producto:cantidades', 'Cantidad', 'Cantidad', Icons.tag),
  ParteProducto('producto:ingredientes', 'Ingredientes', 'Ingredientes', Icons.eco_outlined),
  ParteProducto('producto:adiciones', 'Adiciones', 'Adiciones', Icons.add_circle_outline),
  ParteProducto('producto:grupos', 'Grupos', 'Grupos de opciones', Icons.layers_outlined),
  ParteProducto('producto:promocion', 'Promoción', 'Promoción', Icons.local_offer_outlined),
];

String tituloParte(String seccion, Object? datos) {
  final parte = partesProducto.where((p) => p.seccion == seccion).firstOrNull;
  if (parte == null) return '';
  final nombre = datos is MenuProduct ? datos.name : '';
  return nombre.isNotEmpty ? '${parte.titulo} · $nombre' : parte.titulo;
}
