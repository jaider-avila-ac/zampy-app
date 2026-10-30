class HorarioDia {
  const HorarioDia({
    required this.key,
    required this.label,
    this.abierto = false,
    this.veinticuatro = false,
    this.rangos = const [],
  });

  final String key;
  final String label;
  final bool abierto;
  final bool veinticuatro;
  final List<HorarioRango> rangos;
}

class HorarioRango {
  const HorarioRango({required this.desde, required this.hasta});

  final String desde;
  final String hasta;

  factory HorarioRango.fromJson(Map<String, dynamic> json) => HorarioRango(
    desde: json['desde'] as String? ?? '00:00',
    hasta: json['hasta'] as String? ?? '00:00',
  );
}

const _diasBase = [
  ('lun', 'Lunes'),
  ('mar', 'Martes'),
  ('mie', 'Miércoles'),
  ('jue', 'Jueves'),
  ('vie', 'Viernes'),
  ('sab', 'Sábado'),
  ('dom', 'Domingo'),
];

const _diaJsIndex = ['dom', 'lun', 'mar', 'mie', 'jue', 'vie', 'sab'];

List<HorarioDia> diasConHorario(Map<String, dynamic>? horario) {
  if (horario == null) return const [];
  final result = <HorarioDia>[];
  for (final (key, label) in _diasBase) {
    final raw = horario[key];
    if (raw is! Map) continue;
    final dia = Map<String, dynamic>.from(raw);
    final abierto = dia['abierto'] == true;
    final veinticuatro = dia['veinticuatro'] == true;
    final rangos = (dia['rangos'] as List? ?? [])
        .whereType<Map>()
        .map((r) => HorarioRango.fromJson(Map<String, dynamic>.from(r)))
        .toList();
    final vacio = !abierto || (!veinticuatro && rangos.isEmpty);
    if (vacio) continue;
    result.add(
      HorarioDia(
        key: key,
        label: label,
        abierto: abierto,
        veinticuatro: veinticuatro,
        rangos: rangos,
      ),
    );
  }
  return result;
}

String formatHora(String? hhmm) {
  if (hhmm == null || hhmm.isEmpty) return '';
  final parts = hhmm.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  final period = h < 12 ? 'a.m.' : 'p.m.';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $period';
}

({bool abierto, String? hasta}) computeScheduleStatus(
  Map<String, dynamic>? horario, {
  DateTime? now,
}) {
  if (horario == null) return (abierto: false, hasta: null);
  final date = now ?? DateTime.now();
  final diaKey = _diaJsIndex[date.weekday % 7];
  final raw = horario[diaKey];
  if (raw is! Map || raw['abierto'] != true) {
    return (abierto: false, hasta: null);
  }
  if (raw['veinticuatro'] == true) return (abierto: true, hasta: null);

  final minutosAhora = date.hour * 60 + date.minute;
  for (final rangoRaw in (raw['rangos'] as List? ?? [])) {
    if (rangoRaw is! Map) continue;
    final desde = _minutos(rangoRaw['desde'] as String?);
    final hasta = _minutos(rangoRaw['hasta'] as String?);
    if (minutosAhora >= desde && minutosAhora < hasta) {
      return (abierto: true, hasta: rangoRaw['hasta'] as String?);
    }
  }
  return (abierto: false, hasta: null);
}

int _minutos(String? hhmm) {
  final parts = (hhmm ?? '00:00').split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  return h * 60 + m;
}
