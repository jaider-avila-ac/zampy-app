// Equivalente a src/modules/menu/public/edicion/negocio/imagenes.js en React.
// Las dos imágenes del encabezado: el logo (recortado cuadrado) y la portada.

class ImagenEncabezado {
  const ImagenEncabezado({
    required this.campo,
    required this.carpeta,
    required this.recortarCuadrado,
    required this.etiqueta,
    required this.ayuda,
  });
  final String campo;
  final String carpeta;
  final bool recortarCuadrado;
  final String etiqueta;
  final String ayuda;
}

const imagenesEncabezado = {
  'logo': ImagenEncabezado(
    campo: 'logoUrl',
    carpeta: 'logo',
    recortarCuadrado: true,
    etiqueta: 'Logo',
    ayuda: 'Se recorta cuadrado. PNG o JPG.',
  ),
  'portada': ImagenEncabezado(
    campo: 'bannerUrl',
    carpeta: 'banner',
    recortarCuadrado: false,
    etiqueta: 'Foto de portada',
    ayuda: 'La imagen grande de arriba del menú. Recomendado 1200×400 px.',
  ),
};
