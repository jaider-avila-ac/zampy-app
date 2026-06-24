// Modelos de datos del editor — equivalentes a los tipos del draft en React.
// Todos los modelos tienen fromJson y toJson para serializar de/hacia la API.

String _newId() => 'local_${DateTime.now().microsecondsSinceEpoch}';

// ── Variante de producto (sizes / ingredients / extras) ───────────────────────
class EditorVariant {
  final String id;
  String label;
  double price;

  EditorVariant({required this.id, required this.label, this.price = 0});

  factory EditorVariant.empty() =>
      EditorVariant(id: _newId(), label: '');

  factory EditorVariant.fromJson(Map<String, dynamic> j) => EditorVariant(
        id:    j['id']?.toString() ?? _newId(),
        label: j['label'] as String? ?? j['name'] as String? ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'price': price};
}

// ── Producto del editor ────────────────────────────────────────────────────────
class EditorProduct {
  final String id;
  String name;
  String description;
  double price;
  String categoryId;
  String? imageUrl;
  bool isVisible;
  bool isFeatured;
  bool promoActive;
  double? promoPrice;
  String? promoEndsAt;
  List<String> tags;
  List<String> components;
  List<EditorVariant> sizes;
  List<EditorVariant> ingredients;
  List<EditorVariant> extras;
  List<String> grupoIds;

  EditorProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.description    = '',
    this.imageUrl,
    this.isVisible      = true,
    this.isFeatured     = false,
    this.promoActive    = false,
    this.promoPrice,
    this.promoEndsAt,
    this.tags           = const [],
    this.components     = const [],
    this.sizes          = const [],
    this.ingredients    = const [],
    this.extras         = const [],
    this.grupoIds       = const [],
  });

  factory EditorProduct.empty(String categoryId) => EditorProduct(
        id: _newId(), name: '', price: 0, categoryId: categoryId,
      );

  factory EditorProduct.fromJson(Map<String, dynamic> j) => EditorProduct(
        id:          j['id']?.toString() ?? _newId(),
        name:        j['name']        as String? ?? '',
        description: j['description'] as String? ?? '',
        price:       (j['price']      as num?)?.toDouble() ?? 0,
        categoryId:  j['categoryId']?.toString() ?? j['category']?.toString() ?? '',
        imageUrl:    j['imageUrl']    as String?,
        isVisible:   j['isVisible']   as bool? ?? true,
        isFeatured:  j['isFeatured']  as bool? ?? false,
        promoActive: j['promoActive'] as bool? ?? false,
        promoPrice:  (j['promoPrice'] as num?)?.toDouble(),
        promoEndsAt: j['promoEndsAt'] as String?,
        tags:        (j['tags']       as List?)?.cast<String>() ?? [],
        components:  (j['components'] as List?)?.cast<String>() ?? [],
        sizes:       (j['sizes']       as List? ?? [])
            .map((e) => EditorVariant.fromJson(e as Map<String, dynamic>)).toList(),
        ingredients: (j['ingredients'] as List? ?? [])
            .map((e) => EditorVariant.fromJson(e as Map<String, dynamic>)).toList(),
        extras:      (j['extras']      as List? ?? [])
            .map((e) => EditorVariant.fromJson(e as Map<String, dynamic>)).toList(),
        grupoIds:    (j['grupoIds']    as List? ?? [])
            .map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id':          id,
        'name':        name,
        'description': description,
        'price':       price,
        'categoryId':  categoryId,
        'imageUrl':    imageUrl ?? '',
        'isVisible':   isVisible,
        'isFeatured':  isFeatured,
        'promoActive': promoActive,
        if (promoPrice != null) 'promoPrice': promoPrice,
        if (promoEndsAt != null) 'promoEndsAt': promoEndsAt,
        'tags':        tags,
        'components':  components,
        'sizes':       sizes.where((v) => v.label.trim().isNotEmpty).map((v) => v.toJson()).toList(),
        'ingredients': ingredients.where((v) => v.label.trim().isNotEmpty).map((v) => v.toJson()).toList(),
        'extras':      extras.where((v) => v.label.trim().isNotEmpty).map((v) => v.toJson()).toList(),
        'grupoIds':    grupoIds,
      };

  EditorProduct copyWith({
    String? name, String? description, double? price, String? categoryId,
    String? imageUrl, bool? isVisible, bool? isFeatured, bool? promoActive,
    double? promoPrice, String? promoEndsAt, List<String>? tags,
    List<String>? components, List<EditorVariant>? sizes,
    List<EditorVariant>? ingredients, List<EditorVariant>? extras,
    List<String>? grupoIds,
  }) => EditorProduct(
    id:          id,
    name:        name        ?? this.name,
    description: description ?? this.description,
    price:       price       ?? this.price,
    categoryId:  categoryId  ?? this.categoryId,
    imageUrl:    imageUrl    ?? this.imageUrl,
    isVisible:   isVisible   ?? this.isVisible,
    isFeatured:  isFeatured  ?? this.isFeatured,
    promoActive: promoActive ?? this.promoActive,
    promoPrice:  promoPrice  ?? this.promoPrice,
    promoEndsAt: promoEndsAt ?? this.promoEndsAt,
    tags:        tags        ?? List.from(this.tags),
    components:  components  ?? List.from(this.components),
    sizes:       sizes       ?? List.from(this.sizes),
    ingredients: ingredients ?? List.from(this.ingredients),
    extras:      extras      ?? List.from(this.extras),
    grupoIds:    grupoIds    ?? List.from(this.grupoIds),
  );
}

// ── Categoría del editor ──────────────────────────────────────────────────────
class EditorCategory {
  final String id;
  String name;
  String icon;
  bool isVisible;
  String tipoContenido;
  int order;

  EditorCategory({
    required this.id,
    required this.name,
    this.icon           = 'fork',
    this.isVisible      = true,
    this.tipoContenido  = 'con_imagenes',
    this.order          = 0,
  });

  factory EditorCategory.fromJson(Map<String, dynamic> j) => EditorCategory(
        id:            j['id']?.toString() ?? _newId(),
        name:          j['name']          as String? ?? '',
        icon:          j['icon']          as String? ?? 'fork',
        isVisible:     j['isVisible']     as bool?   ?? true,
        tipoContenido: j['tipoContenido'] as String? ?? 'con_imagenes',
        order:         (j['order']        as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id':            id,
        'name':          name,
        'icon':          icon,
        'isVisible':     isVisible,
        'tipoContenido': tipoContenido,
        'order':         order,
      };
}

// ── Ítem de grupo informativo ─────────────────────────────────────────────────
class EditorGrupoItem {
  final String id;
  String name;
  bool isActive;

  EditorGrupoItem({required this.id, required this.name, this.isActive = true});

  factory EditorGrupoItem.empty() =>
      EditorGrupoItem(id: _newId(), name: '');

  factory EditorGrupoItem.fromJson(dynamic j) {
    if (j is String) return EditorGrupoItem(id: _newId(), name: j);
    final m = j as Map<String, dynamic>;
    return EditorGrupoItem(
      id:       m['id']?.toString() ?? _newId(),
      name:     m['name']     as String? ?? '',
      isActive: m['isActive'] as bool?   ?? true,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'isActive': isActive};
}

// ── Grupo informativo ─────────────────────────────────────────────────────────
class EditorGrupo {
  final String id;
  String name;
  bool isActive;
  List<EditorGrupoItem> items;

  EditorGrupo({
    required this.id,
    required this.name,
    this.isActive = true,
    List<EditorGrupoItem>? items,
  }) : items = items ?? [];

  factory EditorGrupo.empty() =>
      EditorGrupo(id: _newId(), name: '', items: []);

  factory EditorGrupo.fromJson(Map<String, dynamic> j) => EditorGrupo(
        id:       j['id']?.toString() ?? _newId(),
        name:     j['name']     as String? ?? '',
        isActive: j['isActive'] as bool?   ?? true,
        items:    (j['items'] as List? ?? [])
            .map((i) => EditorGrupoItem.fromJson(i)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id':       id,
        'name':     name,
        'isActive': isActive,
        'items':    items.where((i) => i.name.trim().isNotEmpty).map((i) => i.toJson()).toList(),
      };
}

// ── Diseño ────────────────────────────────────────────────────────────────────
class EditorDesign {
  dynamic skinId;
  dynamic paletteId;

  EditorDesign({this.skinId, this.paletteId});

  factory EditorDesign.fromJson(Map<String, dynamic>? j) => EditorDesign(
        skinId:    j?['skinId'],
        paletteId: j?['paletteId'],
      );

  Map<String, dynamic> toJson() => {'skinId': skinId, 'paletteId': paletteId};
}

// ── Info del negocio (editable) ───────────────────────────────────────────────
class EditorInfo {
  String name;
  String slogan;
  String? bannerUrl;
  String? logoUrl;
  String? phone;
  String? whatsapp;
  String? instagram;
  String? facebook;
  String? tiktok;
  String? website;
  String? address;
  String? schedule;
  String? paisIso2;
  String? paisNombre;
  String? div1Iso2;
  String? div1Nombre;
  String? div2Nombre;
  List<String> tags;
  double rating;
  int reviews;

  EditorInfo({
    required this.name,
    this.slogan    = '',
    this.bannerUrl, this.logoUrl, this.phone, this.whatsapp,
    this.instagram, this.facebook, this.tiktok, this.website,
    this.address, this.schedule, this.paisIso2, this.paisNombre,
    this.div1Iso2, this.div1Nombre, this.div2Nombre,
    this.tags      = const [],
    this.rating    = 0,
    this.reviews   = 0,
  });

  factory EditorInfo.fromJson(Map<String, dynamic> j) => EditorInfo(
        name:       j['name']       as String? ?? '',
        slogan:     j['slogan']     as String? ?? '',
        bannerUrl:  j['bannerUrl']  as String?,
        logoUrl:    j['logoUrl']    as String?,
        phone:      j['phone']      as String?,
        whatsapp:   j['whatsapp']   as String?,
        instagram:  j['instagram']  as String?,
        facebook:   j['facebook']   as String?,
        tiktok:     j['tiktok']     as String?,
        website:    j['website']    as String?,
        address:    j['address']    as String?,
        schedule:   j['schedule']   as String?,
        paisIso2:   j['paisIso2']   as String?,
        paisNombre: j['paisNombre'] as String?,
        div1Iso2:   j['div1Iso2']   as String?,
        div1Nombre: j['div1Nombre'] as String?,
        div2Nombre: j['div2Nombre'] as String?,
        tags:       (j['tags']      as List?)?.cast<String>() ?? [],
        rating:     (j['rating']    as num?)?.toDouble() ?? 0,
        reviews:    (j['reviews']   as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name':       name,
        'slogan':     slogan,
        'bannerUrl':  bannerUrl  ?? '',
        'logoUrl':    logoUrl    ?? '',
        'phone':      phone      ?? '',
        'whatsapp':   whatsapp   ?? '',
        'instagram':  instagram  ?? '',
        'facebook':   facebook   ?? '',
        'tiktok':     tiktok     ?? '',
        'website':    website    ?? '',
        'address':    address    ?? '',
        'schedule':   schedule   ?? '',
        'paisIso2':   paisIso2   ?? '',
        'paisNombre': paisNombre ?? '',
        'div1Iso2':   div1Iso2   ?? '',
        'div1Nombre': div1Nombre ?? '',
        'div2Nombre': div2Nombre ?? '',
        'tags':       tags,
        'rating':     rating,
        'reviews':    reviews,
      };
}

// ── Suscripción ───────────────────────────────────────────────────────────────
class EditorSubscription {
  final String  estado;
  final String? tipoPlan;
  final int?    limiteMenus;
  final int?    limiteProductos;
  final int?    limiteCategorias;
  final int?    limiteColaboradores;
  final int?    diasRestantes;
  final int?    minutosRestantes;
  final bool    trialUsado;
  final Map<String, bool> acciones;

  const EditorSubscription({
    required this.estado,
    this.tipoPlan,
    this.limiteMenus,
    this.limiteProductos,
    this.limiteCategorias,
    this.limiteColaboradores,
    this.diasRestantes,
    this.minutosRestantes,
    this.trialUsado      = false,
    this.acciones        = const {},
  });

  factory EditorSubscription.fromJson(Map<String, dynamic>? j) =>
      EditorSubscription(
        estado:               j?['estado']               as String? ?? 'ACTIVA',
        tipoPlan:             j?['tipoPlan']             as String?,
        limiteMenus:          (j?['limiteMenus']         as num?)?.toInt(),
        limiteProductos:      (j?['limiteProductos']     as num?)?.toInt(),
        limiteCategorias:     (j?['limiteCategorias']    as num?)?.toInt(),
        limiteColaboradores:  (j?['limiteColaboradores'] as num?)?.toInt(),
        diasRestantes:        (j?['diasRestantes']       as num?)?.toInt(),
        minutosRestantes:     (j?['minutosRestantes']    as num?)?.toInt(),
        trialUsado:            j?['trialUsado']          as bool? ?? false,
        acciones: (j?['acciones'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v == true)) ??
            {},
      );

  bool get atProductLimit =>
      limiteProductos != null;
  bool productLimitReached(int count) =>
      limiteProductos != null && count >= limiteProductos!;
  bool categoryLimitReached(int count) =>
      limiteCategorias != null && count >= limiteCategorias!;
  bool colaboradorLimitReached(int count) =>
      limiteColaboradores != null && count >= limiteColaboradores!;

  bool accion(String key) => acciones[key] == true;
}

// ── Draft completo ────────────────────────────────────────────────────────────
class EditorDraft {
  EditorInfo info;
  List<EditorCategory> categories;
  List<EditorProduct> products;
  List<EditorGrupo> grupos;
  EditorDesign design;

  EditorDraft({
    required this.info,
    required this.categories,
    required this.products,
    required this.grupos,
    required this.design,
  });

  factory EditorDraft.fromJson(Map<String, dynamic> j) {
    final cats = (j['categories'] as List? ?? [])
        .map((c) => EditorCategory.fromJson(c as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final prods = (j['products'] as List? ?? [])
        .map((p) => EditorProduct.fromJson(p as Map<String, dynamic>))
        .toList();

    final grupos = (j['grupos'] as List? ?? [])
        .map((g) => EditorGrupo.fromJson(g as Map<String, dynamic>))
        .toList();

    return EditorDraft(
      info:       EditorInfo.fromJson(j['info'] as Map<String, dynamic>? ?? {}),
      categories: cats,
      products:   prods,
      grupos:     grupos,
      design:     EditorDesign.fromJson(j['design'] as Map<String, dynamic>?),
    );
  }

  int productsInCategory(String catId) =>
      products.where((p) => p.categoryId == catId).length;
}

// ── Menú completo del editor ──────────────────────────────────────────────────
class EditorMenu {
  final int    id;
  final String slug;
  final String status;
  final int    ownerId;
  final bool   hasDraftChanges;
  final bool   transferible;
  final String? publishedAt;
  final int?   totalVistas;
  final int?   restaurantCategoryId;
  final int?   logrosDias;
  final bool   pendingCheckout;
  final Map<String, dynamic>? cupon;
  final EditorDraft      draft;
  final EditorSubscription subscription;

  const EditorMenu({
    required this.id,
    required this.slug,
    required this.status,
    required this.ownerId,
    required this.hasDraftChanges,
    required this.draft,
    required this.subscription,
    this.transferible = false,
    this.publishedAt,
    this.totalVistas,
    this.restaurantCategoryId,
    this.logrosDias,
    this.pendingCheckout = false,
    this.cupon,
  });

  bool get isPublished => status == 'published';

  factory EditorMenu.fromJson(Map<String, dynamic> j) => EditorMenu(
        id:                    (j['id']                 as num).toInt(),
        slug:                   j['slug']               as String? ?? '',
        status:                 j['status']             as String? ?? 'draft',
        ownerId:               (j['ownerId']            as num?)?.toInt() ?? 0,
        hasDraftChanges:        j['hasDraftChanges']    as bool? ?? false,
        transferible:           j['transferible']       as bool? ?? false,
        publishedAt:            j['publishedAt']        as String?,
        totalVistas:           (j['totalVistas']        as num?)?.toInt(),
        restaurantCategoryId:  (j['catResId']           as num?)?.toInt(),
        logrosDias:            (j['logrosDias']         as num?)?.toInt(),
        pendingCheckout:        j['pendingCheckout']    as bool? ?? false,
        cupon:                  j['cupon']              as Map<String, dynamic>?,
        draft:           EditorDraft.fromJson(j['draft'] as Map<String, dynamic>? ?? {}),
        subscription:    EditorSubscription.fromJson(j['subscription'] as Map<String, dynamic>?),
      );
}
