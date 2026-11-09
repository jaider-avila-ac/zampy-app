class LiveInfo {
  String name;
  String slogan;
  String? logoUrl;
  String? bannerUrl;
  String? phone;
  String? whatsapp;
  String? email;
  String? instagram;
  String? facebook;
  String? tiktok;
  String? website;
  String? address;
  String? municipioCodigo;
  List<String> galeria;
  bool pedidosActivos;

  LiveInfo({
    this.name = '',
    this.slogan = '',
    this.logoUrl,
    this.bannerUrl,
    this.phone,
    this.whatsapp,
    this.email,
    this.instagram,
    this.facebook,
    this.tiktok,
    this.website,
    this.address,
    this.municipioCodigo,
    this.galeria = const [],
    this.pedidosActivos = false,
  });

  factory LiveInfo.fromJson(Map<String, dynamic> j) {
    final ubicacion = j['ubicacion'];
    final ubi = ubicacion is Map
        ? Map<String, dynamic>.from(ubicacion)
        : const {};
    return LiveInfo(
      name: j['name'] as String? ?? '',
      slogan: j['slogan'] as String? ?? '',
      logoUrl: j['logoUrl'] as String?,
      bannerUrl: j['bannerUrl'] as String?,
      phone: j['phone'] as String?,
      whatsapp: j['whatsapp'] as String?,
      email: j['email'] as String?,
      instagram: j['instagram'] as String?,
      facebook: j['facebook'] as String?,
      tiktok: j['tiktok'] as String?,
      website: j['website'] as String?,
      address: j['address'] as String?,
      municipioCodigo:
          ubi['municipioCodigo']?.toString() ??
          j['municipioCodigo']?.toString(),
      galeria: (j['galeria'] as List? ?? []).map((e) => e.toString()).toList(),
      pedidosActivos: j['pedidosActivos'] == true,
    );
  }

  String get municipioNombre {
    return '';
  }
}

class LiveCategory {
  final String codigo;
  String name;
  String icon;
  String tipoContenido;
  int order;
  bool isVisible;

  LiveCategory({
    required this.codigo,
    required this.name,
    this.icon = 'utensils',
    this.tipoContenido = 'con_imagenes',
    this.order = 0,
    this.isVisible = true,
  });

  factory LiveCategory.fromJson(Map<String, dynamic> j) => LiveCategory(
    codigo: (j['codigo'] ?? j['id'] ?? '').toString(),
    name: j['name'] as String? ?? '',
    icon: j['icon'] as String? ?? 'utensils',
    tipoContenido: j['tipoContenido'] as String? ?? 'con_imagenes',
    order: (j['order'] as num?)?.toInt() ?? 0,
    isVisible: j['isVisible'] as bool? ?? true,
  );

  Map<String, dynamic> toBody() => {
    'name': name,
    'icon': icon,
    'tipoContenido': tipoContenido,
    'order': order,
    'isVisible': isVisible,
  };
}

class LiveProduct {
  final String codigo;
  String categoryId;
  String name;
  String description;
  double price;
  String? imageUrl;
  Map<String, dynamic>? imagePosition;
  List<String> tags;
  List<String> components;
  bool isVisible;
  bool isFeatured;
  bool enExplorar;
  bool promoActive;
  double? promoPrice;
  String? promoEndsAt;
  List<Map<String, dynamic>> sizes;
  List<Map<String, dynamic>> ingredients;
  List<Map<String, dynamic>> extras;
  List<String> grupoIds;
  int order;

  LiveProduct({
    required this.codigo,
    required this.categoryId,
    required this.name,
    this.description = '',
    this.price = 0,
    this.imageUrl,
    this.imagePosition,
    this.tags = const [],
    this.components = const [],
    this.isVisible = true,
    this.isFeatured = false,
    this.enExplorar = false,
    this.promoActive = false,
    this.promoPrice,
    this.promoEndsAt,
    this.sizes = const [],
    this.ingredients = const [],
    this.extras = const [],
    this.grupoIds = const [],
    this.order = 0,
  });

  factory LiveProduct.fromJson(Map<String, dynamic> j) => LiveProduct(
    codigo: (j['codigo'] ?? j['id'] ?? '').toString(),
    categoryId: (j['categoryId'] ?? '').toString(),
    name: j['name'] as String? ?? '',
    description: j['description'] as String? ?? '',
    price: (j['price'] as num?)?.toDouble() ?? 0,
    imageUrl: j['imageUrl'] as String?,
    imagePosition: j['imagePosition'] is Map
        ? Map<String, dynamic>.from(j['imagePosition'] as Map)
        : null,
    tags: (j['tags'] as List? ?? []).map((e) => '$e').toList(),
    components: (j['components'] as List? ?? []).map((e) => '$e').toList(),
    isVisible: j['isVisible'] as bool? ?? true,
    isFeatured: j['isFeatured'] as bool? ?? false,
    enExplorar: j['enExplorar'] as bool? ?? false,
    promoActive: j['promoActive'] as bool? ?? false,
    promoPrice: (j['promoPrice'] as num?)?.toDouble(),
    promoEndsAt: j['promoEndsAt'] as String?,
    sizes: _maps(j['sizes']),
    ingredients: _maps(j['ingredients']),
    extras: _maps(j['extras']),
    grupoIds: (j['grupoIds'] as List? ?? []).map((e) => '$e').toList(),
    order: (j['order'] as num?)?.toInt() ?? 0,
  );

  static List<Map<String, dynamic>> _maps(dynamic raw) => (raw as List? ?? [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

class LiveGroup {
  final String codigo;
  String name;
  bool isActive;
  int order;
  List<Map<String, dynamic>> items;

  LiveGroup({
    required this.codigo,
    required this.name,
    this.isActive = true,
    this.order = 0,
    List<Map<String, dynamic>>? items,
  }) : items = items ?? [];

  factory LiveGroup.fromJson(Map<String, dynamic> j) => LiveGroup(
    codigo: (j['codigo'] ?? j['id'] ?? '').toString(),
    name: j['name'] as String? ?? '',
    isActive: j['isActive'] as bool? ?? true,
    order: (j['order'] as num?)?.toInt() ?? 0,
    items: (j['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(),
  );

  Map<String, dynamic> toBody() => {
    'name': name,
    'isActive': isActive,
    'order': order,
    'items': items,
  };
}

class LiveSubscription {
  final String estado;
  final String? tipoPlan;
  final int? limiteProductosTotal;
  final int? limiteCategoriasTotal;
  final int? limiteColaboradores;
  final int? diasRestantes;
  final bool trialUsado;
  final bool pedidosHabilitados;

  const LiveSubscription({
    this.estado = '',
    this.tipoPlan,
    this.limiteProductosTotal,
    this.limiteCategoriasTotal,
    this.limiteColaboradores,
    this.diasRestantes,
    this.trialUsado = false,
    this.pedidosHabilitados = false,
  });

  factory LiveSubscription.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const LiveSubscription();
    return LiveSubscription(
      estado: j['estado'] as String? ?? '',
      tipoPlan: j['tipoPlan'] as String?,
      limiteProductosTotal: (j['limiteProductosTotal'] as num?)?.toInt(),
      limiteCategoriasTotal: (j['limiteCategoriasTotal'] as num?)?.toInt(),
      limiteColaboradores: (j['limiteColaboradores'] as num?)?.toInt(),
      diasRestantes: (j['diasRestantes'] as num?)?.toInt(),
      trialUsado: j['trialUsado'] == true,
      pedidosHabilitados: j['pedidosHabilitados'] == true,
    );
  }

  bool get activa =>
      const {'ACTIVE', 'PAYMENT_REMINDER', 'PAST_DUE'}.contains(estado);
  bool get suspendida => const {'SUSPENDED', 'CANCELED'}.contains(estado);
}

class LiveCoupon {
  final String estado;
  final int diasRestantes;
  final int diasTotal;
  final String? planNombre;

  const LiveCoupon({
    required this.estado,
    this.diasRestantes = 0,
    this.diasTotal = 0,
    this.planNombre,
  });

  factory LiveCoupon.fromJson(Map<String, dynamic> j) => LiveCoupon(
    estado: j['estado'] as String? ?? '',
    diasRestantes: (j['diasRestantes'] as num?)?.toInt() ?? 0,
    diasTotal: (j['diasTotal'] as num?)?.toInt() ?? 0,
    planNombre: j['planNombre'] as String?,
  );

  bool get activo => estado == 'ACTIVO';
  bool get pendiente => estado == 'PENDIENTE';
  bool get existe => activo || pendiente;
}

class LiveMenu {
  final String codigo;
  final String slug;
  final String status;
  final bool esPropio;
  final String? miRol;
  final LiveInfo info;
  final LiveSubscription subscription;
  final LiveCoupon? cupon;
  final Map<String, dynamic>? horario;
  final int? logrosDias;
  final bool pendingCheckout;
  // false con mesas de cuenta abierta, pedidos sin resolver o cobro automático activo.
  final bool transferible;
  final List<LiveCategory> categories;
  final List<LiveProduct> products;
  final List<LiveGroup> groups;
  final String? categoriaCodigo;
  final String? skinId;
  final String? paletteId;

  LiveMenu({
    required this.codigo,
    required this.slug,
    required this.status,
    required this.esPropio,
    this.miRol,
    required this.info,
    this.subscription = const LiveSubscription(),
    this.cupon,
    this.horario,
    this.logrosDias,
    this.pendingCheckout = false,
    this.transferible = true,
    this.categories = const [],
    this.products = const [],
    this.groups = const [],
    this.categoriaCodigo,
    this.skinId,
    this.paletteId,
  });

  factory LiveMenu.fromJson(Map<String, dynamic> j) {
    final draft = j['draft'] is Map
        ? Map<String, dynamic>.from(j['draft'] as Map)
        : <String, dynamic>{};
    final info = draft['info'] is Map
        ? Map<String, dynamic>.from(draft['info'] as Map)
        : <String, dynamic>{};
    return LiveMenu(
      codigo: (j['codigo'] ?? j['id'] ?? '').toString(),
      slug: j['slug'] as String? ?? '',
      status: j['status'] as String? ?? 'draft',
      esPropio: j['esPropio'] == true,
      miRol: j['miRol'] as String?,
      info: LiveInfo.fromJson(info),
      subscription: LiveSubscription.fromJson(
        j['subscription'] is Map
            ? Map<String, dynamic>.from(j['subscription'] as Map)
            : null,
      ),
      cupon: j['cupon'] is Map
          ? LiveCoupon.fromJson(Map<String, dynamic>.from(j['cupon'] as Map))
          : null,
      horario: j['horario'] is Map
          ? Map<String, dynamic>.from(j['horario'] as Map)
          : null,
      logrosDias: (j['logrosDias'] as num?)?.toInt(),
      pendingCheckout: j['pendingCheckout'] == true,
      transferible: j['transferible'] != false,
      categories: (draft['categories'] as List? ?? [])
          .whereType<Map>()
          .map((e) => LiveCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      products: (draft['products'] as List? ?? [])
          .whereType<Map>()
          .map((e) => LiveProduct.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      groups: (draft['grupos'] as List? ?? [])
          .whereType<Map>()
          .map((e) => LiveGroup.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      categoriaCodigo: j['categoriaCodigo']?.toString(),
      skinId: draft['design'] is Map
          ? draft['design']['skinId']?.toString()
          : null,
      paletteId: draft['design'] is Map
          ? draft['design']['paletteId']?.toString()
          : null,
    );
  }

  bool get publicado => status == 'published';
  bool get isOwner => esPropio;
  bool get puedeGestionar => esPropio || miRol == 'editor';
  bool get esMesero => miRol == 'mesero';
  bool get esRepartidor => miRol == 'repartidor';
  bool get tieneBeneficio => cupon?.existe == true;
  bool get tieneAcceso => subscription.activa || tieneBeneficio;
}
