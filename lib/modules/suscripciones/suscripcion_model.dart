class Precio {
  final String display;
  const Precio({required this.display});
  factory Precio.fromJson(Map<String, dynamic> j) =>
      Precio(display: j['display'] as String? ?? '');
}

class Suscripcion {
  final String estado;
  final DateTime? trialFin;
  final DateTime? periodoFin;
  final int diasRestantes;
  final int? precioActualCentavos;

  const Suscripcion({
    required this.estado,
    this.trialFin,
    this.periodoFin,
    required this.diasRestantes,
    this.precioActualCentavos,
  });

  factory Suscripcion.fromJson(Map<String, dynamic> j) => Suscripcion(
        estado: j['estado'] as String? ?? '',
        trialFin: j['trialFin'] != null
            ? DateTime.tryParse(j['trialFin'] as String)
            : null,
        periodoFin: j['periodoFin'] != null
            ? DateTime.tryParse(j['periodoFin'] as String)
            : null,
        diasRestantes: (j['diasRestantes'] as num?)?.toInt() ?? 0,
        precioActualCentavos:
            (j['precioActualCentavos'] as num?)?.toInt(),
      );

  bool get needsPay =>
      estado == 'PAYMENT_REMINDER' || estado == 'PAST_DUE';
}

class MenuConSuscripcion {
  final int id;
  final String slug;
  final String? name;
  final Suscripcion? subscription;

  const MenuConSuscripcion({
    required this.id,
    required this.slug,
    this.name,
    this.subscription,
  });

  factory MenuConSuscripcion.fromJson(Map<String, dynamic> j) {
    final draft = j['draft'] as Map<String, dynamic>?;
    final info = draft?['info'] as Map<String, dynamic>?;
    final subJson = j['subscription'] as Map<String, dynamic>?;
    return MenuConSuscripcion(
      id: (j['id'] as num).toInt(),
      slug: j['slug'] as String? ?? '',
      name: info?['name'] as String?,
      subscription: subJson != null ? Suscripcion.fromJson(subJson) : null,
    );
  }

  String get displayName => name?.isNotEmpty == true ? name! : slug.isNotEmpty ? slug : 'Menú $id';
}
