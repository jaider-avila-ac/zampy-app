import '../producto/partes_producto.dart';

// Equivalente a src/modules/menu/public/edicion/panel/secciones.js en React.
// Las secciones del menú que se editan en el panel (las del producto son producto:<parte>, ver partes_producto).

const _titulos = {
  'logo': 'Cambiar logo',
  'portada': 'Cambiar portada',
  'informacion': 'Información del negocio',
  'categorias': 'Categorías',
  'producto-nuevo': 'Nuevo producto',
  'tema': 'Tema del menú',
};

/// Las que se pueden abrir con `?editar=sección` al llegar al menú (desde "Completa tu menú").
const seccionesDeEnlace = ['logo', 'portada', 'informacion', 'categorias', 'producto-nuevo', 'tema'];

String tituloSeccion(String seccion, Object? datos) => _titulos[seccion] ?? tituloParte(seccion, datos);
