import 'package:flutter/material.dart';

// Equivalente a src/modules/menu/public/edicion/cabecera/opcionesEdicion.js en React.

/// Una opción del menú de edición: abre una sección del panel o lleva a una pantalla aparte (ruta, para lo que
/// todavía no se edita en el propio menú, como el horario).
class OpcionEdicion {
  const OpcionEdicion({required this.icono, required this.texto, this.seccion, this.ruta});
  final IconData icono;
  final String texto;
  final String? seccion;
  final String Function(String menuCodigo)? ruta;
}

class GrupoEdicion {
  const GrupoEdicion(this.titulo, this.opciones);
  final String titulo;
  final List<OpcionEdicion> opciones;
}

final gruposEdicion = [
  GrupoEdicion('Tu negocio', [
    const OpcionEdicion(icono: Icons.info_outline, texto: 'Información del negocio', seccion: 'informacion'),
    OpcionEdicion(icono: Icons.schedule, texto: 'Horario', ruta: (c) => '/menus/$c/info?paso=horario'),
  ]),
  const GrupoEdicion('Catálogo', [
    OpcionEdicion(icono: Icons.create_new_folder_outlined, texto: 'Categorías', seccion: 'categorias'),
    OpcionEdicion(icono: Icons.add_box_outlined, texto: 'Agregar producto', seccion: 'producto-nuevo'),
  ]),
  const GrupoEdicion('Diseño', [
    OpcionEdicion(icono: Icons.palette_outlined, texto: 'Tema del menú', seccion: 'tema'),
  ]),
];
