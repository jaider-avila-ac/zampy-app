import 'dart:ui';

// Modelos de datos para el menú público
// Equivalente a los tipos usados en usePublicMenu.js y MenuPage.jsx en React

// ── Tema del menú (equivale al ThemeContext de React) ────────────────────────
class MenuTheme {
  final Color primary;
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color navBg;
  final Color navText;
  final Color navBorder;
  final String skinId;

  const MenuTheme({
    required this.primary,
    this.bg         = const Color(0xFFF8FAFC),
    this.surface    = const Color(0xFFFFFFFF),
    this.surfaceAlt = const Color(0xFFF1F5F9),
    this.text       = const Color(0xFF0F172A),
    this.textMuted  = const Color(0xFF64748B),
    this.border     = const Color(0xFFE2E8F0),
    this.navBg      = const Color(0xFFFFFFFF),
    this.navText    = const Color(0xFF0F172A),
    this.navBorder  = const Color(0xFFE2E8F0),
    this.skinId     = 'default',
  });

  // Parsea el objeto theme.colors que devuelve el backend
  factory MenuTheme.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MenuTheme(primary: Color(0xFF4F46E5));

    final col = json['colors'] as Map<String, dynamic>? ?? {};

    Color p(String key, Color fallback) => _parseHex(col[key] as String?) ?? fallback;

    final primary    = p('primary',    const Color(0xFF4F46E5));
    final bg         = p('bg',         const Color(0xFFF8FAFC));
    final surface    = p('surface',    const Color(0xFFFFFFFF));
    final surfaceAlt = p('surfaceAlt', const Color(0xFFF1F5F9));
    final text       = p('text',       const Color(0xFF0F172A));
    final textMuted  = p('textMuted',  const Color(0xFF64748B));
    final border     = p('border',     const Color(0xFFE2E8F0));
    final navBg      = p('navBg',      const Color(0xFFFFFFFF));
    final navBorder  = p('navBorder',  const Color(0xFFE2E8F0));
    final navText    = _isLight(navBg) ? text : const Color(0xFFFFFFFF);
    final skinId     = json['skinId']?.toString() ?? 'default';

    return MenuTheme(
      primary: primary, bg: bg, surface: surface,
      surfaceAlt: surfaceAlt, text: text, textMuted: textMuted,
      border: border, navBg: navBg, navText: navText, navBorder: navBorder,
      skinId: skinId,
    );
  }

  static bool _isLight(Color c) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return (r * 299 + g * 587 + b * 114) / 1000 > 145;
  }

  static Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.replaceAll('#', '');
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    } else if (h.length == 8) {
      return Color(int.parse(h, radix: 16));
    }
    return null;
  }
}

// ── Info del negocio ─────────────────────────────────────────────────────────
class MenuInfo {
  final String  name;
  final String? slogan;
  final String? bannerUrl;
  final String? logoUrl;
  final String? address;
  final String? schedule;
  final String? phone;
  final String? whatsapp;
  final String? instagram;
  final String? facebook;
  final String? tiktok;
  final String? website;
  final String? paisNombre;
  final String? div1Nombre;
  final String? div2Nombre;

  const MenuInfo({
    required this.name,
    this.slogan, this.bannerUrl, this.logoUrl, this.address,
    this.schedule, this.phone, this.whatsapp, this.instagram,
    this.facebook, this.tiktok, this.website, this.paisNombre,
    this.div1Nombre, this.div2Nombre,
  });

  factory MenuInfo.fromJson(Map<String, dynamic> json) => MenuInfo(
    name:       json['name']       as String? ?? json['nombreNegocio'] as String? ?? '',
    slogan:     json['slogan']     as String?,
    bannerUrl:  json['bannerUrl']  as String?,
    logoUrl:    json['logoUrl']    as String?,
    address:    json['address']    as String?,
    schedule:   json['schedule']   as String?,
    phone:      json['phone']      as String?,
    whatsapp:   json['whatsapp']   as String?,
    instagram:  json['instagram']  as String?,
    facebook:   json['facebook']   as String?,
    tiktok:     json['tiktok']     as String?,
    website:    json['website']    as String?,
    paisNombre: json['paisNombre'] as String?,
    div1Nombre: json['div1Nombre'] as String?,
    div2Nombre: json['div2Nombre'] as String?,
  );
}

// ── Categoría ────────────────────────────────────────────────────────────────
class MenuCategory {
  final String  id;
  final String  name;
  final String? icon;
  final bool    isVisible;
  final String  tipoContenido;

  const MenuCategory({
    required this.id,
    required this.name,
    this.icon,
    this.isVisible     = true,
    this.tipoContenido = 'con_imagenes',
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
    id:             json['id']?.toString()            ?? '',
    name:           json['name']   as String?         ?? json['label'] as String? ?? '',
    icon:           json['icon']   as String?,
    isVisible:      json['isVisible'] as bool?        ?? true,
    tipoContenido:  json['tipoContenido'] as String?  ?? 'con_imagenes',
  );
}

// ── Variante de producto ──────────────────────────────────────────────────────
class ProductVariant {
  final String  name;
  final double? price;

  const ProductVariant({required this.name, this.price});

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    name:  json['name']  as String? ?? '',
    price: (json['price'] as num?)?.toDouble(),
  );
}

// ── Producto ─────────────────────────────────────────────────────────────────
class MenuProduct {
  final String        id;
  final String        name;
  final String?       description;
  final double        price;
  final double?       promoPrice;
  final bool          promoActive;
  final String?       promoEndsAt;
  final String?       imageUrl;
  final String        categoryId;
  final bool          isVisible;
  final List<String>  tags;
  final List<String>  components;
  final List<ProductVariant> variants;
  final double?       rating;
  final int?          totalVotos;

  const MenuProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.description, this.promoPrice, this.promoActive = false,
    this.promoEndsAt, this.imageUrl, this.isVisible = true,
    this.tags = const [], this.components = const [],
    this.variants = const [], this.rating, this.totalVotos,
  });

  factory MenuProduct.fromJson(Map<String, dynamic> json) {
    final tagsList = (json['tags'] as List?)?.cast<String>() ?? [];
    final compList = (json['components'] as List?)?.cast<String>() ?? [];
    final varList  = (json['variants']  as List?)
        ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
        .toList() ?? [];

    return MenuProduct(
      id:          json['id']?.toString()          ?? '',
      name:        json['name']         as String? ?? '',
      description: json['description']  as String?,
      price:       (json['price']       as num?)?.toDouble() ?? 0,
      promoPrice:  (json['promoPrice']  as num?)?.toDouble(),
      promoActive: json['promoActive']  as bool?  ?? false,
      promoEndsAt: json['promoEndsAt']  as String?,
      imageUrl:    json['imageUrl']     as String?,
      categoryId:  json['categoryId']?.toString() ?? json['category']?.toString() ?? '',
      isVisible:   json['isVisible']    as bool?  ?? true,
      tags:        tagsList,
      components:  compList,
      variants:    varList,
      rating:      (json['rating']      as num?)?.toDouble(),
      totalVotos:  (json['totalVotos']  as num?)?.toInt(),
    );
  }

  // Precio efectivo (respeta promo si está activa)
  double get effectivePrice {
    if (promoActive && promoPrice != null) {
      if (promoEndsAt == null) return promoPrice!;
      if (DateTime.now().isBefore(DateTime.parse(promoEndsAt!))) return promoPrice!;
    }
    return price;
  }

  bool get hasPromo =>
    promoActive && promoPrice != null &&
    (promoEndsAt == null || DateTime.now().isBefore(DateTime.parse(promoEndsAt!)));
}

// ── Menú completo ─────────────────────────────────────────────────────────────
class PublicMenuData {
  final MenuInfo              info;
  final MenuTheme             theme;
  final List<MenuCategory>    categories;
  final List<MenuProduct>     products;
  final int?                  ownerId;

  const PublicMenuData({
    required this.info,
    required this.theme,
    required this.categories,
    required this.products,
    this.ownerId,
  });

  factory PublicMenuData.fromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as List? ?? [])
        .map((c) => MenuCategory.fromJson(c as Map<String, dynamic>))
        .where((c) => c.isVisible)
        .toList();

    final prods = (json['products'] as List? ?? [])
        .map((p) => MenuProduct.fromJson(p as Map<String, dynamic>))
        .where((p) => p.isVisible)
        .toList();

    return PublicMenuData(
      info:       MenuInfo.fromJson(json['info'] as Map<String, dynamic>? ?? json),
      theme:      MenuTheme.fromJson(json['theme'] as Map<String, dynamic>?),
      categories: cats,
      products:   prods,
      ownerId:    (json['ownerId'] as num?)?.toInt(),
    );
  }

  // Productos de una categoría
  List<MenuProduct> productsForCategory(String catId) =>
      products.where((p) => p.categoryId == catId).toList();

  // Primer producto visible de cada categoría (para sorpresa)
  List<MenuProduct> get surpriseProducts =>
      products.where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty).toList();
}

// ── Item del feed de exploración ──────────────────────────────────────────────
class MenuFeedItem {
  final int     menId;
  final String  slug;
  final String  nombreNegocio;
  final String? slogan;
  final String? bannerUrl;
  final String? logoUrl;
  final String? ciudad;
  final String? iconoCategoria;
  final int     meEncantas;

  const MenuFeedItem({
    required this.menId,
    required this.slug,
    required this.nombreNegocio,
    this.slogan, this.bannerUrl, this.logoUrl, this.ciudad,
    this.iconoCategoria, this.meEncantas = 0,
  });

  factory MenuFeedItem.fromJson(Map<String, dynamic> json) => MenuFeedItem(
    menId:          (json['menId']          as num?)?.toInt() ?? 0,
    slug:           json['slug']            as String? ?? '',
    nombreNegocio:  json['nombreNegocio']   as String? ?? json['name'] as String? ?? '',
    slogan:         json['slogan']          as String?,
    bannerUrl:      json['bannerUrl']       as String?,
    logoUrl:        json['logoUrl']         as String?,
    ciudad:         json['ciudad']          as String?,
    iconoCategoria: json['iconoCategoria']  as String?,
    meEncantas:     (json['meEncantas']     as num?)?.toInt() ?? 0,
  );
}

// ── Feed de exploración ───────────────────────────────────────────────────────
class ExploreFeed {
  final List<MenuFeedItem> nearby;
  final List<MenuFeedItem> trending;
  final List<MenuFeedItem> nuevo;

  const ExploreFeed({
    this.nearby   = const [],
    this.trending = const [],
    this.nuevo    = const [],
  });

  static const empty = ExploreFeed();

  factory ExploreFeed.fromJson(Map<String, dynamic> json) {
    List<MenuFeedItem> parse(String key) {
      final list = json[key] as List? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(MenuFeedItem.fromJson)
          .toList();
    }
    return ExploreFeed(
      nearby:   parse('nearby'),
      trending: parse('trending'),
      nuevo:    parse('nuevo'),
    );
  }
}

// ── Resultado de scroll infinito ──────────────────────────────────────────────
class ScrollResult {
  final List<MenuFeedItem> items;
  final String?            nextCursor;
  final bool               hasMore;

  const ScrollResult({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });

  factory ScrollResult.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MenuFeedItem.fromJson)
        .toList();
    return ScrollResult(
      items:      list,
      nextCursor: json['nextCursor'] as String?,
      hasMore:    json['hasMore']    as bool? ?? false,
    );
  }

  static const empty = ScrollResult(items: []);
}
