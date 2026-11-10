import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment;

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
  final double cardRadius;
  final double buttonRadius;
  final double badgeRadius;

  const MenuTheme({
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
    this.cardRadius = 16.0,
    this.buttonRadius = 20.0,
    this.badgeRadius = 99.0,
  });

  // Parsea el objeto theme.colors que devuelve el backend
  factory MenuTheme.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MenuTheme(primary: Color(0xFF4F46E5));

    final col = json['colors'] as Map<String, dynamic>? ?? {};

    Color p(String key, Color fallback) =>
        _parseHex(col[key] as String?) ?? fallback;

    final primary = p('primary', const Color(0xFF4F46E5));
    final bg = p('bg', const Color(0xFFF8FAFC));
    final surface = p('surface', const Color(0xFFFFFFFF));
    final surfaceAlt = p('surfaceAlt', const Color(0xFFF1F5F9));
    final text = p('text', const Color(0xFF0F172A));
    final textMuted = p('textMuted', const Color(0xFF64748B));
    final border = p('border', const Color(0xFFE2E8F0));
    final navBg = p('navBg', const Color(0xFFFFFFFF));
    final navBorder = p('navBorder', const Color(0xFFE2E8F0));
    final navText = _isLight(navBg) ? text : const Color(0xFFFFFFFF);
    final skinId = json['skinId']?.toString() ?? 'default';

    final rad = json['radius'] as Map<String, dynamic>? ?? {};
    final cardRadius = (rad['card'] as num?)?.toDouble() ?? 16.0;
    final buttonRadius = (rad['button'] as num?)?.toDouble() ?? 20.0;
    final badgeRadius = (rad['badge'] as num?)?.toDouble() ?? 99.0;

    return MenuTheme(
      primary: primary,
      bg: bg,
      surface: surface,
      surfaceAlt: surfaceAlt,
      text: text,
      textMuted: textMuted,
      border: border,
      navBg: navBg,
      navText: navText,
      navBorder: navBorder,
      skinId: skinId,
      cardRadius: cardRadius,
      buttonRadius: buttonRadius,
      badgeRadius: badgeRadius,
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

// ── Ubicación geográfica ─────────────────────────────────────────────────────
class MenuUbicacion {
  final String? paisCodigo;
  final String? pais;
  final String? divisionCodigo;
  final String? division;
  final String? divisionTipo;
  final String? municipioCodigo;
  final String? municipio;

  const MenuUbicacion({
    this.paisCodigo,
    this.pais,
    this.divisionCodigo,
    this.division,
    this.divisionTipo,
    this.municipioCodigo,
    this.municipio,
  });

  factory MenuUbicacion.fromJson(Map<String, dynamic> json) => MenuUbicacion(
    paisCodigo: json['paisCodigo']?.toString(),
    pais: json['pais']?.toString(),
    divisionCodigo: json['divisionCodigo']?.toString(),
    division: json['division']?.toString(),
    divisionTipo: json['divisionTipo']?.toString(),
    municipioCodigo: json['municipioCodigo']?.toString(),
    municipio: json['municipio']?.toString(),
  );

  String get texto => [
    municipio,
    division,
    pais,
  ].where((s) => s != null && s.isNotEmpty).join(', ');
}

// ── Info del negocio ─────────────────────────────────────────────────────────
class MenuInfo {
  final String name;
  final String? slogan;
  final String? bannerUrl;
  final String? logoUrl;
  final String? address;
  final String? schedule;
  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? instagram;
  final String? facebook;
  final String? tiktok;
  final String? website;
  final String? paisNombre;
  final String? div1Nombre;
  final String? div2Nombre;
  final List<String> galeria;
  final List<String> tags;
  final bool pedidosActivos;
  final String pedidosModo; // 'sistema' (se registra) | 'whatsapp' (solo mensaje)
  final MenuUbicacion? ubicacion;

  const MenuInfo({
    required this.name,
    this.slogan,
    this.bannerUrl,
    this.logoUrl,
    this.address,
    this.schedule,
    this.email,
    this.phone,
    this.whatsapp,
    this.instagram,
    this.facebook,
    this.tiktok,
    this.website,
    this.paisNombre,
    this.div1Nombre,
    this.div2Nombre,
    this.galeria = const [],
    this.tags = const [],
    this.pedidosActivos = false,
    this.pedidosModo = 'sistema',
    this.ubicacion,
  });

  // Helpers — igual que React: solo muestra si no es null y no está vacío
  bool get hasInstagram => instagram != null && instagram!.isNotEmpty;
  bool get hasFacebook => facebook != null && facebook!.isNotEmpty;
  bool get hasTiktok => tiktok != null && tiktok!.isNotEmpty;
  bool get hasWebsite => website != null && website!.isNotEmpty;
  bool get hasWhatsapp => whatsapp != null && whatsapp!.isNotEmpty;
  bool get hasPhone => phone != null && phone!.isNotEmpty;
  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get hasAddress => address != null && address!.isNotEmpty;
  bool get hasSchedule => schedule != null && schedule!.isNotEmpty;
  bool get hasGaleria => galeria.isNotEmpty;

  String get locationText {
    final ubicacionTexto = ubicacion?.texto ?? '';
    if (ubicacionTexto.isNotEmpty) return ubicacionTexto;
    return [
      paisNombre,
      div1Nombre,
      div2Nombre,
    ].where((s) => s != null && s.isNotEmpty).join(', ');
  }

  factory MenuInfo.fromJson(Map<String, dynamic> json) => MenuInfo(
    name: json['name'] as String? ?? json['nombreNegocio'] as String? ?? '',
    slogan: json['slogan'] as String?,
    bannerUrl: json['bannerUrl'] as String?,
    logoUrl: json['logoUrl'] as String?,
    address: json['address'] as String?,
    schedule: json['schedule'] as String?,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    whatsapp: json['whatsapp'] as String?,
    instagram: json['instagram'] as String?,
    facebook: json['facebook'] as String?,
    tiktok: json['tiktok'] as String?,
    website: json['website'] as String?,
    paisNombre: json['paisNombre'] as String?,
    div1Nombre: json['div1Nombre'] as String?,
    div2Nombre: json['div2Nombre'] as String?,
    galeria:
        (json['galeria'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    tags: (json['tags'] as List?)?.cast<String>() ?? const [],
    pedidosActivos: json['pedidosActivos'] as bool? ?? false,
    pedidosModo: json['pedidosModo'] == 'whatsapp' ? 'whatsapp' : 'sistema',
    ubicacion: json['ubicacion'] is Map
        ? MenuUbicacion.fromJson(
            Map<String, dynamic>.from(json['ubicacion'] as Map),
          )
        : null,
  );
}

// ── Categoría ────────────────────────────────────────────────────────────────
class MenuCategory {
  final String id;
  final String name;
  final String? icon;
  final bool isVisible;
  final String tipoContenido;
  final int order;

  const MenuCategory({
    required this.id,
    required this.name,
    this.icon,
    this.isVisible = true,
    this.tipoContenido = 'con_imagenes',
    this.order = 0,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
    id: (json['id'] ?? json['codigo'] ?? '').toString(),
    name: json['name'] as String? ?? json['label'] as String? ?? '',
    icon: json['icon'] as String?,
    isVisible: json['isVisible'] as bool? ?? true,
    tipoContenido: json['tipoContenido'] as String? ?? 'con_imagenes',
    order: (json['order'] as num?)?.toInt() ?? 0,
  );
}

// ── Variante de producto ──────────────────────────────────────────────────────
class ProductVariant {
  final String name;
  final double? price;

  const ProductVariant({required this.name, this.price});

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    name: json['name'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble(),
  );
}

// ── Tamaño de producto (React: product.sizes) ─────────────────────────────────
class ProductSize {
  final String id;
  final String label;
  final double price;
  // Número del tamaño (ej. "4 ingredientes" → 4), para grupos con límite "según el tamaño". Null = sin tope.
  final int? cantidad;

  const ProductSize({required this.id, required this.label, this.price = 0, this.cantidad});

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    final label = json['label'] as String? ?? json['name'] as String? ?? '';
    return ProductSize(
      id: (json['id'] ?? label).toString(),
      label: label,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      cantidad: (json['cantidad'] as num?)?.toInt(),
    );
  }
}

// ── Modificador de producto (ingredientes / adiciones) ────────────────────────
class ProductModifier {
  final String id;
  final String label;
  final double price;

  const ProductModifier({
    required this.id,
    required this.label,
    this.price = 0,
  });

  factory ProductModifier.fromJson(Map<String, dynamic> json) {
    final label = json['label'] as String? ?? json['name'] as String? ?? '';
    return ProductModifier(
      id: (json['id'] ?? label).toString(),
      label: label,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ── Grupo informativo (React: grupos) ─────────────────────────────────────────
class MenuGrupoItem {
  final String id;
  final String name;
  final double price;
  final bool isActive;

  const MenuGrupoItem({
    required this.id,
    required this.name,
    this.price = 0,
    this.isActive = true,
  });

  factory MenuGrupoItem.fromJson(dynamic raw) {
    if (raw is String) {
      return MenuGrupoItem(id: raw, name: raw);
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final name = map['name'] as String? ?? map['label'] as String? ?? '';
      return MenuGrupoItem(
        id: (map['id'] ?? name).toString(),
        name: name,
        price: (map['price'] as num?)?.toDouble() ?? 0,
        isActive: map['isActive'] as bool? ?? true,
      );
    }
    return MenuGrupoItem(id: raw.toString(), name: raw.toString());
  }
}

class MenuGrupo {
  final String id;
  final String name;
  final bool isActive;
  final List<MenuGrupoItem> items;
  // Límite de selección: 'ninguno' | 'fijo' | 'segun_cantidad'.
  final String seleccionModo;
  final int? seleccionMax;
  // Informativo: sus elementos solo se muestran, no se seleccionan ni suman precio.
  final bool informativo;

  const MenuGrupo({
    required this.id,
    required this.name,
    this.isActive = true,
    this.items = const [],
    this.seleccionModo = 'ninguno',
    this.seleccionMax,
    this.informativo = false,
  });

  List<String> get itemNames => items.map((item) => item.name).toList();

  factory MenuGrupo.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final parsedItems = rawItems
        .map(MenuGrupoItem.fromJson)
        .where((item) => item.name.isNotEmpty && item.isActive)
        .toList();

    return MenuGrupo(
      id: (json['id'] ?? json['codigo'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      items: parsedItems,
      seleccionModo: json['seleccionModo'] == 'fijo'
          ? 'fijo'
          : (json['seleccionModo'] == 'segun_cantidad' ? 'segun_cantidad' : 'ninguno'),
      seleccionMax: (json['seleccionMax'] as num?)?.toInt(),
      informativo: json['informativo'] as bool? ?? false,
    );
  }
}

// ── Producto ─────────────────────────────────────────────────────────────────
class MenuProduct {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? promoPrice;
  final bool promoActive;
  final String? promoEndsAt;
  final String? imageUrl;
  final String categoryId;
  final bool isVisible;
  final List<String> tags;
  final List<String> components;
  final List<ProductVariant> variants;
  final List<ProductSize> sizes;
  final List<ProductSize> cantidades; // selector "Cantidad" (reusa ProductSize + cantidad)
  final String? cantidadTitulo;
  final List<ProductModifier> ingredients;
  final List<ProductModifier> extras;
  final List<String> grupoIds;
  final double? rating;
  final int? totalVotos;
  final bool isFeatured;
  // qué parte de la foto se ve en la tarjeta, en porcentaje (0-100); 50/50 = centro
  final double imageX;
  final double imageY;
  // si el producto aparece en Explorar (el dueño puede quitarlo)
  final bool enExplorar;
  final int order;

  // la posición de la foto como alineación (equivale a object-position de React)
  Alignment get imageAlignment => Alignment(imageX / 50 - 1, imageY / 50 - 1);

  const MenuProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.description,
    this.promoPrice,
    this.promoActive = false,
    this.promoEndsAt,
    this.imageUrl,
    this.isVisible = true,
    this.tags = const [],
    this.components = const [],
    this.variants = const [],
    this.sizes = const [],
    this.cantidades = const [],
    this.cantidadTitulo,
    this.ingredients = const [],
    this.extras = const [],
    this.grupoIds = const [],
    this.rating,
    this.totalVotos,
    this.isFeatured = false,
    this.imageX = 50,
    this.imageY = 50,
    this.enExplorar = true,
    this.order = 0,
  });

  factory MenuProduct.fromJson(Map<String, dynamic> json) {
    final tagsList = (json['tags'] as List?)?.cast<String>() ?? [];
    final compList = (json['components'] as List?)?.cast<String>() ?? [];
    final varList = (json['variants'] as List? ?? [])
        .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
        .toList();
    final sizeList = (json['sizes'] as List? ?? [])
        .map((s) => ProductSize.fromJson(s as Map<String, dynamic>))
        .toList();
    final cantidadList = (json['cantidades'] as List? ?? [])
        .map((s) => ProductSize.fromJson(s as Map<String, dynamic>))
        .toList();
    final ingList = (json['ingredients'] as List? ?? [])
        .map((i) => ProductModifier.fromJson(i as Map<String, dynamic>))
        .toList();
    final extList = (json['extras'] as List? ?? [])
        .map((e) => ProductModifier.fromJson(e as Map<String, dynamic>))
        .toList();
    final grupoIdsList = (json['grupoIds'] as List? ?? [])
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return MenuProduct(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      promoPrice: (json['promoPrice'] as num?)?.toDouble(),
      promoActive: json['promoActive'] as bool? ?? false,
      promoEndsAt: json['promoEndsAt'] as String?,
      imageUrl: json['imageUrl'] as String?,
      categoryId:
          json['categoryId']?.toString() ?? json['category']?.toString() ?? '',
      isVisible: json['isVisible'] as bool? ?? true,
      tags: tagsList,
      components: compList,
      variants: varList,
      sizes: sizeList,
      cantidades: cantidadList,
      cantidadTitulo: json['cantidadTitulo'] as String?,
      ingredients: ingList,
      extras: extList,
      grupoIds: grupoIdsList,
      rating: (json['rating'] as num?)?.toDouble(),
      totalVotos: (json['totalVotos'] as num?)?.toInt(),
      isFeatured: json['isFeatured'] as bool? ?? false,
      imageX: ((json['imagePosition'] as Map?)?['x'] as num?)?.toDouble() ?? 50,
      imageY: ((json['imagePosition'] as Map?)?['y'] as num?)?.toDouble() ?? 50,
      enExplorar: json['enExplorar'] != false,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  // Precio efectivo (respeta promo si está activa)
  double get effectivePrice {
    if (promoActive && promoPrice != null) {
      if (promoEndsAt == null) return promoPrice!;
      if (DateTime.now().isBefore(DateTime.parse(promoEndsAt!))) {
        return promoPrice!;
      }
    }
    return price;
  }

  bool get hasPromo =>
      promoActive &&
      promoPrice != null &&
      (promoEndsAt == null ||
          DateTime.now().isBefore(DateTime.parse(promoEndsAt!)));
}

// ── Design del menú (skinId + paletteId del backend) ─────────────────────────
class MenuDesign {
  final dynamic skinId;
  final dynamic paletteId;

  const MenuDesign({this.skinId, this.paletteId});

  factory MenuDesign.fromJson(Map<String, dynamic>? json) =>
      MenuDesign(skinId: json?['skinId'], paletteId: json?['paletteId']);
}

// ── Menú completo ─────────────────────────────────────────────────────────────
class PublicMenuData {
  final MenuInfo info;
  final MenuTheme theme;
  final List<MenuCategory> categories;
  final List<MenuProduct> products;
  final List<MenuGrupo> grupos;
  final MenuDesign? design;
  final String? menuId;
  final String slug;
  final bool esPropio;
  final String? miRol;
  final bool publicado;
  final Map<String, dynamic>? horario;
  final String? categoriaCodigo;
  final MenuUbicacion? ubicacion;

  const PublicMenuData({
    required this.info,
    required this.theme,
    required this.categories,
    required this.products,
    this.grupos = const [],
    this.design,
    this.menuId,
    this.slug = '',
    this.esPropio = false,
    this.miRol,
    this.publicado = false,
    this.horario,
    this.categoriaCodigo,
    this.ubicacion,
  });

  PublicMenuData copyWithTheme(MenuTheme newTheme) => PublicMenuData(
    info: info,
    theme: newTheme,
    categories: categories,
    products: products,
    grupos: grupos,
    design: design,
    menuId: menuId,
    slug: slug,
    esPropio: esPropio,
    miRol: miRol,
    publicado: publicado,
    horario: horario,
    categoriaCodigo: categoriaCodigo,
    ubicacion: ubicacion,
  );

  // incluirOcultos: el dueño o el editor ven también las categorías y productos ocultos (para editarlos)
  factory PublicMenuData.fromRoot(
    Map<String, dynamic> root, {
    MenuTheme? catalogTheme,
    bool incluirOcultos = false,
    bool preferirBorrador = false,
  }) {
    Map<String, dynamic>? asMap(dynamic value) =>
        value is Map ? Map<String, dynamic>.from(value) : null;

    final published = asMap(root['published']);
    final draft = asMap(root['draft']);
    // En la edición (preview) se usa SIEMPRE el borrador —lo que el dueño está
    // editando—, igual que React (getPreviewData usa menu.draft). Nunca el
    // snapshot publicado, que puede estar vacío o desfasado. En la vista
    // pública se usa el snapshot publicado.
    final content = preferirBorrador
        ? (draft ?? published ?? root)
        : (published ?? draft ?? root);

    final infoMap = asMap(content['info']) ?? content;
    final designMap = asMap(content['design']) ?? asMap(root['design']);
    final themeMap = asMap(root['theme']) ?? asMap(content['theme']);
    final themeJson = themeMap == null
        ? null
        : <String, dynamic>{
            ...themeMap,
            'skinId': designMap?['skinId'] ?? themeMap['skinId'],
          };

    final cats =
        (content['categories'] as List? ?? [])
            .whereType<Map>()
            .map((c) => MenuCategory.fromJson(Map<String, dynamic>.from(c)))
            .where((c) => incluirOcultos || c.isVisible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    final prods =
        (content['products'] as List? ?? [])
            .whereType<Map>()
            .map((p) => MenuProduct.fromJson(Map<String, dynamic>.from(p)))
            .where((p) => incluirOcultos || p.isVisible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    final gruposList = (content['grupos'] as List? ?? [])
        .whereType<Map>()
        .map((g) => MenuGrupo.fromJson(Map<String, dynamic>.from(g)))
        .where((g) => g.isActive)
        .toList();

    final ubicacion = asMap(root['ubicacion']) ?? asMap(infoMap['ubicacion']);
    final infoJson = <String, dynamic>{...infoMap};
    if (ubicacion != null) {
      infoJson['ubicacion'] = ubicacion;
    }

    return PublicMenuData(
      info: MenuInfo.fromJson(infoJson),
      theme: themeJson != null
          ? MenuTheme.fromJson(themeJson)
          : (catalogTheme ?? const MenuTheme(primary: Color(0xFF4F46E5))),
      categories: cats,
      products: prods,
      grupos: gruposList,
      design: MenuDesign.fromJson(designMap),
      menuId: (root['codigo'] ?? root['id'] ?? root['menuId'])?.toString(),
      slug: root['slug'] as String? ?? '',
      esPropio: root['esPropio'] == true,
      miRol: root['miRol'] as String?,
      // En edición, el estado publicado sale de 'status' (como React:
      // menu.status === 'published'); un snapshot que haya quedado no implica
      // que el menú esté publicado ahora. En la vista pública basta con que
      // venga el snapshot.
      publicado: preferirBorrador
          ? (root['status'] == 'published' || root['publicado'] == true)
          : (published != null ||
                root['status'] == 'published' ||
                root['publicado'] == true),
      horario: asMap(root['horario']) ?? asMap(content['horario']),
      categoriaCodigo: (root['categoriaCodigo'] ?? root['categoria'])
          ?.toString(),
      ubicacion: ubicacion == null ? null : MenuUbicacion.fromJson(ubicacion),
    );
  }

  factory PublicMenuData.fromJson(Map<String, dynamic> json) =>
      PublicMenuData.fromRoot(json);

  // Productos de una categoría
  List<MenuProduct> productsForCategory(String catId) =>
      products.where((p) => p.categoryId == catId).toList();

  List<MenuProduct> get featuredProducts =>
      products.where((p) => p.isFeatured).toList();

  // Primer producto visible de cada categoría (para sorpresa)
  List<MenuProduct> get surpriseProducts => products
      .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
      .toList();
}

// ── Item del feed de exploración ──────────────────────────────────────────────
class MenuFeedItem {
  final int menId;
  final String slug;
  final String nombreNegocio;
  final String? slogan;
  final String? bannerUrl;
  final String? logoUrl;
  final String? ciudad;
  final String? iconoCategoria;
  final int meEncantas;

  const MenuFeedItem({
    required this.menId,
    required this.slug,
    required this.nombreNegocio,
    this.slogan,
    this.bannerUrl,
    this.logoUrl,
    this.ciudad,
    this.iconoCategoria,
    this.meEncantas = 0,
  });

  factory MenuFeedItem.fromJson(Map<String, dynamic> json) => MenuFeedItem(
    menId: (json['menId'] as num?)?.toInt() ?? 0,
    slug: json['slug'] as String? ?? '',
    nombreNegocio:
        json['nombreNegocio'] as String? ?? json['name'] as String? ?? '',
    slogan: json['slogan'] as String?,
    bannerUrl: json['bannerUrl'] as String?,
    logoUrl: json['logoUrl'] as String?,
    ciudad: json['ciudad'] as String?,
    iconoCategoria: json['iconoCategoria'] as String?,
    meEncantas: (json['meEncantas'] as num?)?.toInt() ?? 0,
  );
}

// ── Feed de exploración ───────────────────────────────────────────────────────
class ExploreFeed {
  final List<MenuFeedItem> nearby;
  final List<MenuFeedItem> trending;
  final List<MenuFeedItem> nuevo;

  const ExploreFeed({
    this.nearby = const [],
    this.trending = const [],
    this.nuevo = const [],
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
      nearby: parse('nearby'),
      trending: parse('trending'),
      nuevo: parse('nuevo'),
    );
  }
}

// ── Resultado de scroll infinito ──────────────────────────────────────────────
class ScrollResult {
  final List<MenuFeedItem> items;
  final String? nextCursor;
  final bool hasMore;

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
      items: list,
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  static const empty = ScrollResult(items: []);
}
