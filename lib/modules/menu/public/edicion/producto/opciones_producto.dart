// Equivalente a src/modules/menu/public/edicion/producto/opcionesProducto.js en React.
// Tamaños, ingredientes y adiciones: una lista de nombre (+ precio), cada una con su endpoint
// (PUT /menus/{menú}/productos/{producto}/{tipo}).

class OpcionProducto {
  const OpcionProducto({
    required this.conPrecio,
    required this.max,
    required this.placeholder,
    required this.ayuda,
    this.conCantidad = false,
    this.conTitulo = false,
  });
  final bool conPrecio;
  final int max; // tope por producto (coincide con el backend)
  final String placeholder;
  final String ayuda;
  // Solo "Cantidad": campo "cantidad" (el número para grupos con límite "según la cantidad").
  final bool conCantidad;
  // Solo "Cantidad": título configurable de la sección.
  final bool conTitulo;
}

const opcionesProducto = {
  'tamanos': OpcionProducto(
    conPrecio: true,
    max: 10,
    placeholder: 'Ej: Grande',
    ayuda: 'Cada tamaño tiene su propio precio. Sin tamaños se usa el precio del producto.',
  ),
  'cantidades': OpcionProducto(
    conPrecio: true,
    conCantidad: true,
    conTitulo: true,
    max: 12,
    placeholder: 'Ej: 4 ingredientes',
    ayuda: 'Una sola elección con su propio precio (reemplaza el precio base). La "cantidad" es el número que usa un grupo con límite "según la cantidad".',
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
