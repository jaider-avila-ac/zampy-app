// Equivalente a src/modules/menu/public/edicion/producto/opcionesProducto.js en React.
// Tamaños, ingredientes y adiciones: una lista de nombre (+ precio), cada una con su endpoint
// (PUT /menus/{menú}/productos/{producto}/{tipo}).

class OpcionProducto {
  const OpcionProducto({
    required this.conPrecio,
    required this.max,
    required this.placeholder,
    required this.ayuda,
  });
  final bool conPrecio;
  final int max; // tope por producto (coincide con el backend)
  final String placeholder;
  final String ayuda;
}

const opcionesProducto = {
  'tamanos': OpcionProducto(
    conPrecio: true,
    max: 10,
    placeholder: 'Ej: Grande',
    ayuda: 'Cada tamaño tiene su propio precio. Sin tamaños se usa el precio del producto.',
  ),
  'ingredientes': OpcionProducto(
    conPrecio: false,
    max: 25,
    placeholder: 'Ej: Cebolla',
    ayuda: 'El cliente puede pedir quitar cualquiera de estos ingredientes.',
  ),
  'adiciones': OpcionProducto(
    conPrecio: true,
    max: 25,
    placeholder: 'Ej: Tocineta',
    ayuda: 'Lo que el cliente puede agregar, con su precio adicional.',
  ),
};
