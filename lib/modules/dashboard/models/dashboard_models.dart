import '../../explore/models/explore_models.dart';

class MisMenusData {
  final List<TarjetaMenu> items;
  final int? limiteMenus;

  const MisMenusData({required this.items, this.limiteMenus});

  factory MisMenusData.fromJson(Map<String, dynamic> json) => MisMenusData(
    items: (json['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => TarjetaMenu.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    limiteMenus: (json['limiteMenus'] as num?)?.toInt(),
  );
}

class ColaboracionMenu {
  final String codigo;
  final String slug;
  final String nombre;
  final String? slogan;
  final String? logoUrl;
  final String? estado;
  final String? miRol;

  const ColaboracionMenu({
    required this.codigo,
    required this.slug,
    required this.nombre,
    this.slogan,
    this.logoUrl,
    this.estado,
    this.miRol,
  });

  factory ColaboracionMenu.fromJson(Map<String, dynamic> json) {
    final draft = json['draft'];
    final info = draft is Map ? draft['info'] : null;
    final infoMap = info is Map ? Map<String, dynamic>.from(info) : const {};
    return ColaboracionMenu(
      codigo: (json['codigo'] ?? json['id'] ?? '').toString(),
      slug: json['slug'] as String? ?? '',
      nombre: (infoMap['name'] as String? ?? '').trim(),
      slogan: infoMap['slogan'] as String?,
      logoUrl: infoMap['logoUrl'] as String?,
      estado: json['status'] as String? ?? json['estado'] as String?,
      miRol: json['miRol'] as String?,
    );
  }

  bool get publicado => estado == 'publicado' || estado == 'published';

  String get rolLabel => switch (miRol) {
    'mesero' => 'Mesero',
    'repartidor' => 'Repartidor',
    _ => 'Editor',
  };
}

class PasoMenu {
  final String codigo;
  final bool completo;
  final bool obligatorio;

  const PasoMenu({
    required this.codigo,
    required this.completo,
    required this.obligatorio,
  });

  factory PasoMenu.fromJson(Map<String, dynamic> json) => PasoMenu(
    codigo: json['codigo'] as String? ?? '',
    completo: json['completo'] == true,
    obligatorio: json['obligatorio'] == true,
  );
}

class MenuResumen {
  final String codigo;
  final String slug;
  final String nombre;
  final String status;
  final bool esPropio;
  final String? miRol;
  final List<PasoMenu> pasos;

  const MenuResumen({
    required this.codigo,
    required this.slug,
    required this.nombre,
    required this.status,
    required this.esPropio,
    this.miRol,
    this.pasos = const [],
  });

  factory MenuResumen.fromJson(Map<String, dynamic> json) {
    final draft = json['draft'];
    final info = draft is Map ? draft['info'] : null;
    final infoMap = info is Map ? Map<String, dynamic>.from(info) : const {};
    return MenuResumen(
      codigo: (json['codigo'] ?? json['id'] ?? '').toString(),
      slug: json['slug'] as String? ?? '',
      nombre: (infoMap['name'] as String? ?? '').trim(),
      status: json['status'] as String? ?? 'borrador',
      esPropio: json['esPropio'] == true,
      miRol: json['miRol'] as String?,
      pasos: (json['pasos'] as List? ?? [])
          .whereType<Map>()
          .map((e) => PasoMenu.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  bool get publicado => status == 'publicado' || status == 'published';
  bool get puedeGestionar => esPropio || miRol == 'editor';
  bool get esMesero => miRol == 'mesero';
  bool get esRepartidor => miRol == 'repartidor';
}
