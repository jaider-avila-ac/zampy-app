class TarjetaMenu {
  final String codigo;
  final String slug;
  final String nombre;
  final String? logoUrl;
  final String? categoria;
  final String? municipio;
  final String? estado;

  const TarjetaMenu({
    required this.codigo,
    required this.slug,
    required this.nombre,
    this.logoUrl,
    this.categoria,
    this.municipio,
    this.estado,
  });

  String get nombreDisplay => nombre.trim().isNotEmpty ? nombre : slug;

  factory TarjetaMenu.fromJson(Map<String, dynamic> json) => TarjetaMenu(
    codigo: (json['codigo'] ?? json['id'] ?? '').toString(),
    slug: json['slug'] as String? ?? '',
    nombre: (json['nombre'] ?? json['nombreNegocio'] ?? '').toString(),
    logoUrl: json['logoUrl'] as String?,
    categoria: json['categoria'] as String?,
    municipio: json['municipio'] as String? ?? json['ciudad'] as String?,
    estado: json['estado'] as String?,
  );
}

class TarjetaProducto {
  final String codigo;
  final String nombre;
  final String? imagenUrl;
  final String menuSlug;
  final String menuNombre;
  final int meEncantas;

  const TarjetaProducto({
    required this.codigo,
    required this.nombre,
    required this.menuSlug,
    required this.menuNombre,
    this.imagenUrl,
    this.meEncantas = 0,
  });

  factory TarjetaProducto.fromJson(Map<String, dynamic> json) =>
      TarjetaProducto(
        codigo: (json['codigo'] ?? json['id'] ?? '').toString(),
        nombre: json['nombre'] as String? ?? '',
        imagenUrl: json['imagenUrl'] as String? ?? json['imageUrl'] as String?,
        menuSlug: json['menuSlug'] as String? ?? '',
        menuNombre: json['menuNombre'] as String? ?? '',
        meEncantas: (json['meEncantas'] as num?)?.toInt() ?? 0,
      );
}

class ExploreFiltroOpcion {
  final String codigo;
  final String nombre;
  final String? detalle;

  const ExploreFiltroOpcion({
    required this.codigo,
    required this.nombre,
    this.detalle,
  });

  factory ExploreFiltroOpcion.fromJson(Map<String, dynamic> json) =>
      ExploreFiltroOpcion(
        codigo: (json['codigo'] ?? '').toString(),
        nombre: (json['nombre'] ?? '').toString(),
        detalle: json['detalle'] as String?,
      );
}

class ExploreFiltros {
  final List<ExploreFiltroOpcion> categorias;
  final List<ExploreFiltroOpcion> lugares;

  const ExploreFiltros({this.categorias = const [], this.lugares = const []});

  static const empty = ExploreFiltros();

  factory ExploreFiltros.fromJson(Map<String, dynamic> json) {
    List<ExploreFiltroOpcion> parse(String key) => (json[key] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ExploreFiltroOpcion.fromJson)
        .toList();

    return ExploreFiltros(
      categorias: parse('categorias'),
      lugares: parse('lugares'),
    );
  }
}

class MenuScrollPage {
  final List<TarjetaMenu> items;
  final String? nextCursor;
  final bool hasMore;

  const MenuScrollPage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });

  factory MenuScrollPage.fromJson(Map<String, dynamic> json) => MenuScrollPage(
    items: (json['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TarjetaMenu.fromJson)
        .toList(),
    nextCursor: json['nextCursor'] as String?,
    hasMore: json['hasMore'] as bool? ?? false,
  );
}

class ProductosPage {
  final List<TarjetaProducto> items;
  final String? siguiente;

  const ProductosPage({required this.items, this.siguiente});

  factory ProductosPage.fromJson(Map<String, dynamic> json) => ProductosPage(
    items: (json['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TarjetaProducto.fromJson)
        .toList(),
    siguiente: json['siguiente'] as String?,
  );
}
