/// Modelo equivalente al objeto de menu que devuelve el backend en explore.
/// Mapea los mismos campos que usa MenuCard.jsx en la versión web.
class MenuFeedItem {
  const MenuFeedItem({
    required this.menId,
    required this.nombreNegocio,
    this.slogan,
    this.bannerUrl,
    this.logoUrl,
    this.iconoCategoria,
    this.ciudad,
    this.meEncantas = 0,
    required this.slug,
  });

  final int menId;
  final String nombreNegocio;
  final String? slogan;
  final String? bannerUrl;
  final String? logoUrl;
  final String? iconoCategoria;
  final String? ciudad;
  final int meEncantas;
  final String slug;

  factory MenuFeedItem.fromJson(Map<String, dynamic> json) => MenuFeedItem(
        menId: (json['menId'] as num).toInt(),
        nombreNegocio: (json['nombreNegocio'] as String?) ?? '',
        slogan: json['slogan'] as String?,
        bannerUrl: json['bannerUrl'] as String?,
        logoUrl: json['logoUrl'] as String?,
        iconoCategoria: json['iconoCategoria'] as String?,
        ciudad: json['ciudad'] as String?,
        meEncantas: (json['meEncantas'] as num?)?.toInt() ?? 0,
        slug: (json['slug'] as String?) ?? '',
      );
}

/// Feed principal: todos + secciones (nearby, trending, nuevo).
/// Equivalente a la respuesta de GET /api/explore/feed.
class ExploreFeed {
  const ExploreFeed({
    this.todos    = const [],
    this.nearby   = const [],
    this.trending = const [],
    this.nuevo    = const [],
  });

  final List<MenuFeedItem> todos;
  final List<MenuFeedItem> nearby;
  final List<MenuFeedItem> trending;
  final List<MenuFeedItem> nuevo;

  factory ExploreFeed.fromJson(Map<String, dynamic> json) {
    List<MenuFeedItem> parse(String key) {
      final list = json[key];
      if (list is! List) return [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(MenuFeedItem.fromJson)
          .toList();
    }
    return ExploreFeed(
      todos:    parse('todos'),
      nearby:   parse('nearby'),
      trending: parse('trending'),
      nuevo:    parse('nuevo'),
    );
  }

  static const empty = ExploreFeed();
}
