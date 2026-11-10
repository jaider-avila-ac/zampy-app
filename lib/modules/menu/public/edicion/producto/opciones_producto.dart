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
  });
  final bool conPrecio;
  final int max; // tope por producto (coincide con el backend)
  final String placeholder;
  final String ayuda;
  // Solo tamaños: campo "cantidad" (el número para grupos con límite "según el tamaño").
  final bool conCantidad;
}

const opcionesProducto = {
  'tamanos': OpcionProducto(
    conPrecio: true,
    conCantidad: true,
    max: 10,
    placeholder: 'Ej: Grande',
    ayuda: 'Cada tamaño tiene su propio precio. La "cantidad" (opcional) es el número que usa un grupo con límite "según el tamaño" (ej. "4 ingredientes" → 4).',
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
