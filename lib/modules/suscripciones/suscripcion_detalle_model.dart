class Pago {
  final int id;
  final int montoCentavos;
  final String estado;
  final String? metodo;
  final String? wompiId;
  final DateTime? creadoEn;
  final DateTime? periodoInicio;
  final DateTime? periodoFin;

  const Pago({
    required this.id,
    required this.montoCentavos,
    required this.estado,
    this.metodo,
    this.wompiId,
    this.creadoEn,
    this.periodoInicio,
    this.periodoFin,
  });

  factory Pago.fromJson(Map<String, dynamic> j) => Pago(
        id: (j['id'] as num).toInt(),
        montoCentavos: (j['montoCentavos'] as num?)?.toInt() ?? 0,
        estado: j['estado'] as String? ?? '',
        metodo: j['metodo'] as String?,
        wompiId: j['wompiId'] as String?,
        creadoEn: j['creadoEn'] != null
            ? DateTime.tryParse(j['creadoEn'] as String)
            : null,
        periodoInicio: j['periodoInicio'] != null
            ? DateTime.tryParse(j['periodoInicio'] as String)
            : null,
        periodoFin: j['periodoFin'] != null
            ? DateTime.tryParse(j['periodoFin'] as String)
            : null,
      );
}

class SuscripcionDetalle {
  final String? estado;
  final DateTime? pruebaInicio;
  final DateTime? pruebaFin;
  final DateTime? periodoInicio;
  final DateTime? periodoFin;
  final int diasRestantes;
  final int precioActualCentavos;
  final int? precioBasicoCentavos;
  final int? precioAvanzadoCentavos;
  final int? limiteBasicoPlan;
  final int? limiteAvanzadoPlan;
  final bool trialUsado;
  final String? tipoPlan;
  final List<Pago> pagos;

  const SuscripcionDetalle({
    this.estado,
    this.pruebaInicio,
    this.pruebaFin,
    this.periodoInicio,
    this.periodoFin,
    required this.diasRestantes,
    required this.precioActualCentavos,
    this.precioBasicoCentavos,
    this.precioAvanzadoCentavos,
    this.limiteBasicoPlan,
    this.limiteAvanzadoPlan,
    required this.trialUsado,
    this.tipoPlan,
    required this.pagos,
  });

  bool get hasSus => estado != null && estado!.isNotEmpty;
  bool get needsPay =>
      estado == 'PAYMENT_REMINDER' || estado == 'PAST_DUE';
  bool get isPending => estado == 'PENDING_PAYMENT';
  bool get isWaitingAct => estado == 'WAITING_ACTIVATION';

  factory SuscripcionDetalle.fromJson(Map<String, dynamic> j) {
    final pagosRaw = j['pagos'] as List? ?? [];
    return SuscripcionDetalle(
      estado: j['estado'] as String?,
      pruebaInicio: j['pruebaInicio'] != null
          ? DateTime.tryParse(j['pruebaInicio'] as String)
          : null,
      pruebaFin: j['pruebaFin'] != null
          ? DateTime.tryParse(j['pruebaFin'] as String)
          : null,
      periodoInicio: j['periodoInicio'] != null
          ? DateTime.tryParse(j['periodoInicio'] as String)
          : null,
      periodoFin: j['periodoFin'] != null
          ? DateTime.tryParse(j['periodoFin'] as String)
          : null,
      diasRestantes: (j['diasRestantes'] as num?)?.toInt() ?? 0,
      precioActualCentavos:
          (j['precioActualCentavos'] as num?)?.toInt() ?? 0,
      precioBasicoCentavos:
          (j['precioBasicoCentavos'] as num?)?.toInt(),
      precioAvanzadoCentavos:
          (j['precioAvanzadoCentavos'] as num?)?.toInt(),
      limiteBasicoPlan:
          (j['limiteBasicoPlan'] as num?)?.toInt(),
      limiteAvanzadoPlan:
          (j['limiteAvanzadoPlan'] as num?)?.toInt(),
      trialUsado: j['trialUsado'] as bool? ?? false,
      tipoPlan: j['tipoPlan'] as String?,
      pagos: pagosRaw
          .whereType<Map<String, dynamic>>()
          .map(Pago.fromJson)
          .toList(),
    );
  }
}
