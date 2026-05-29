import 'dart:ui';

// ── Theme ─────────────────────────────────────────────────────────────────────

class MenuPublicoTheme {
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

  const MenuPublicoTheme({
    required this.primary,
    this.bg = const Color(0xFFF8FAFC),
    this.surface = const Color(0xFFFFFFFF),
    this.surfaceAlt = const Color(0xFFF1F5F9),
    this.text = const Color(0xFF0F172A),
    this.textMuted = const Color(0xFF64748B),
    this.border = const Color(0xFFE2E8F0),
    this.navBg = const Color(0xFFFFFFFF),
    this.navText = const Color(0xFF0F172A),
    this.navBorder = const Color(0xFFE2E8F0),
    this.skinId = 'default',
  });


  /// El backend envía theme.colors con el set completo computado.
  /// Equivalente a backendThemeToPalette() en ThemeContext.jsx.
  factory MenuPublicoTheme.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MenuPublicoTheme(primary: Color(0xFF4F46E5));

    // colors es el objeto plano con todos los valores
    final col = json['colors'] as Map<String, dynamic>? ?? {};

    Color p(String key, Color fallback) =>
        _parseHex(col[key] as String?) ?? fallback;

    final primary    = p('primary',    const Color(0xFF4F46E5));
    final bg         = p('bg',         const Color(0xFFF8FAFC));
    final surface    = p('surface',    const Color(0xFFFFFFFF));
    final surfaceAlt = p('surfaceAlt', const Color(0xFFF1F5F9));
    final text       = p('text',       const Color(0xFF0F172A));
    final textMuted  = p('textMuted',  const Color(0xFF64748B));
    final border     = p('border',     const Color(0xFFE2E8F0));
    final navBg      = p('navBg',      const Color(0xFFFFFFFF));
    final navBorder  = p('navBorder',  const Color(0xFFE2E8F0));
    // navText = isLight(navBg) ? text : white  (mismo cálculo que JSX)
    final navText    = _isLight(navBg) ? text : const Color(0xFFFFFFFF);
    final skinId     = json['skinId'] as String? ?? 'default';

    return MenuPublicoTheme(
      primary:    primary,
      bg:         bg,
      surface:    surface,
      surfaceAlt: surfaceAlt,
      text:       text,
      textMuted:  textMuted,
      border:     border,
      navBg:      navBg,
      navText:    navText,
      navBorder:  navBorder,
      skinId:     skinId,
    );
  }

  /// Igual que isLight() en ThemeContext.jsx
  static bool _isLight(Color c) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return (r * 299 + g * 587 + b * 114) / 1000 > 145;
  }

  static Color? _parseHex(String? hex) {
    if (hex == null) return null;
    try {
      final h = hex.replaceAll('#', '');
      final full = h.length == 6 ? 'FF$h' : h;
      return Color(int.parse(full, radix: 16));
    } catch (_) {
      return null;
    }
  }

  static String fmtPrice(num value) {
    final s = value.round().toString();
    final buf = StringBuffer();
    final len = s.length;
    for (int i = 0; i < len; i++) {
      buf.write(s[i]);
      final rem = len - i - 1;
      if (rem > 0 && rem % 3 == 0) buf.write('.');
    }
    return buf.toString();
  }
}

// ── Business Info ─────────────────────────────────────────────────────────────

class BusinessInfo {
  final String name;
  final String? slogan;
  final String? logoUrl;
  final String? bannerUrl;
  final double? rating;
  final int? reviews;
  final String? address;
  final String? phone;
  final String? whatsapp;
  final String? schedule;
  final List<String> tags;

  const BusinessInfo({
    required this.name,
    this.slogan,
    this.logoUrl,
    this.bannerUrl,
    this.rating,
    this.reviews,
    this.address,
    this.phone,
    this.whatsapp,
    this.schedule,
    this.tags = const [],
  });

  factory BusinessInfo.fromJson(Map<String, dynamic> j) => BusinessInfo(
        name: j['name'] as String? ?? '',
        slogan: j['slogan'] as String?,
        logoUrl: j['logoUrl'] as String?,
        bannerUrl: j['bannerUrl'] as String? ?? j['banner'] as String?,
        rating: (j['rating'] as num?)?.toDouble(),
        reviews: (j['reviews'] as num?)?.toInt(),
        address: j['address'] as String?,
        phone: j['phone'] as String?,
        whatsapp: j['whatsapp'] as String?,
        schedule: j['schedule'] as String?,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

// ── Category ──────────────────────────────────────────────────────────────────

class MenuCategory {
  final String id;
  final String label;
  final String? icon;
  final bool isVisible;
  final String tipoContenido;

  const MenuCategory({
    required this.id,
    required this.label,
    this.icon,
    this.isVisible = true,
    this.tipoContenido = 'con_imagenes',
  });

  factory MenuCategory.fromJson(Map<String, dynamic> j) => MenuCategory(
        id: j['id']?.toString() ?? '',
        label: j['label'] as String? ?? j['name'] as String? ?? '',
        icon: j['icon'] as String?,
        isVisible: j['isVisible'] as bool? ?? true,
        tipoContenido: j['tipoContenido'] as String? ?? 'con_imagenes',
      );
}

// ── Product Variant ───────────────────────────────────────────────────────────

class ProductoVariante {
  final String id;
  final String label;
  final double price;

  const ProductoVariante({
    required this.id,
    required this.label,
    this.price = 0,
  });

  factory ProductoVariante.fromJson(Map<String, dynamic> j) => ProductoVariante(
        id: j['id']?.toString() ?? '',
        label: j['label'] as String? ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
      );
}

// ── Grupo Info ────────────────────────────────────────────────────────────────

class GrupoInfo {
  final String id;
  final String name;
  final List<String> items;
  final bool isActive;

  const GrupoInfo({
    required this.id,
    required this.name,
    this.items = const [],
    this.isActive = true,
  });

  factory GrupoInfo.fromJson(Map<String, dynamic> j) => GrupoInfo(
        id: j['id']?.toString() ?? '',
        name: j['name'] as String? ?? '',
        items: (j['items'] as List?)?.map((e) => e.toString()).toList() ?? [],
        isActive: j['isActive'] as bool? ?? true,
      );
}

// ── Producto ──────────────────────────────────────────────────────────────────

class Producto {
  final String id;
  final String name;
  final String? description;
  final String? image;
  final double price;
  final bool promoActive;
  final double? promoPrice;
  final DateTime? promoEndsAt;
  final List<String> tags;
  final double? rating;
  final String? category;
  final bool isVisible;
  final bool isFeatured;
  final List<ProductoVariante> sizes;
  final List<ProductoVariante> ingredients;
  final List<ProductoVariante> extras;
  final List<String> components;
  final List<String> grupoIds;

  const Producto({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.price,
    this.promoActive = false,
    this.promoPrice,
    this.promoEndsAt,
    this.tags = const [],
    this.rating,
    this.category,
    this.isVisible = true,
    this.isFeatured = false,
    this.sizes = const [],
    this.ingredients = const [],
    this.extras = const [],
    this.components = const [],
    this.grupoIds = const [],
  });

  bool get hasPromo =>
      promoActive &&
      promoPrice != null &&
      promoPrice! > 0 &&
      (promoEndsAt == null || promoEndsAt!.isAfter(DateTime.now()));

  double get displayPrice => hasPromo ? promoPrice! : price;

  factory Producto.fromJson(Map<String, dynamic> j) {
    List<ProductoVariante> parseVariants(String key) {
      final list = j[key] as List?;
      if (list == null) return [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ProductoVariante.fromJson)
          .toList();
    }

    return Producto(
      id: j['id']?.toString() ?? '',
      name: j['name'] as String? ?? '',
      description: j['description'] as String?,
      image: j['imageUrl'] as String? ?? j['image'] as String?,
      price: (j['price'] as num?)?.toDouble() ?? 0,
      promoActive: j['promoActive'] as bool? ?? false,
      promoPrice: (j['promoPrice'] as num?)?.toDouble(),
      promoEndsAt: j['promoEndsAt'] != null
          ? DateTime.tryParse(j['promoEndsAt'] as String)
          : null,
      tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      rating: (j['rating'] as num?)?.toDouble(),
      category: j['categoryId']?.toString() ?? j['category']?.toString(),
      isVisible: j['isVisible'] as bool? ?? true,
      isFeatured: j['isFeatured'] as bool? ?? false,
      sizes: parseVariants('sizes'),
      ingredients: parseVariants('ingredients'),
      extras: parseVariants('extras'),
      components:
          (j['components'] as List?)?.map((e) => e.toString()).toList() ?? [],
      grupoIds:
          (j['grupoIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

// ── Full menu data ────────────────────────────────────────────────────────────

class MenuPublicoData {
  final int menuId;
  final String slug;
  final int? ownerId;
  final MenuPublicoTheme theme;
  final BusinessInfo business;
  final List<MenuCategory> categories;
  final List<Producto> products;
  final List<GrupoInfo> grupos;

  const MenuPublicoData({
    required this.menuId,
    required this.slug,
    this.ownerId,
    required this.theme,
    required this.business,
    required this.categories,
    required this.products,
    required this.grupos,
  });

  List<MenuCategory> get visibleCategories =>
      categories.where((c) => c.isVisible).toList();

  List<Producto> get visibleProducts =>
      products.where((p) => p.isVisible).toList();

  List<Producto> productsForCategory(String catId) =>
      visibleProducts.where((p) => p.category == catId).toList();

  List<Producto> get featured =>
      visibleProducts.where((p) => p.isFeatured).toList();

  factory MenuPublicoData.fromJson(Map<String, dynamic> j) {
    final info = j['info'] as Map<String, dynamic>? ?? {};
    final rawCats = j['categories'] as List? ?? [];
    final rawProds = j['products'] as List? ?? [];
    final rawGrupos = j['grupos'] as List? ?? [];

    return MenuPublicoData(
      menuId: (j['menuId'] as num?)?.toInt() ?? 0,
      slug: j['slug'] as String? ?? '',
      ownerId: (j['ownerId'] as num?)?.toInt(),
      theme: MenuPublicoTheme.fromJson(j['theme'] as Map<String, dynamic>?),
      business: BusinessInfo.fromJson(info),
      categories: rawCats
          .whereType<Map<String, dynamic>>()
          .map(MenuCategory.fromJson)
          .toList(),
      products: rawProds
          .whereType<Map<String, dynamic>>()
          .map(Producto.fromJson)
          .toList(),
      grupos: rawGrupos
          .whereType<Map<String, dynamic>>()
          .map(GrupoInfo.fromJson)
          .toList(),
    );
  }
}
