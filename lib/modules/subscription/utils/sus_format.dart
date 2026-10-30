// Formatos compartidos del módulo de suscripción.
// Equivalentes a utils/fmtTiempo.js y a fmtCOP/fmtFecha de las páginas de React.

/// Tiempo restante en la unidad más legible; usa minutos si vienen, si no días.
String fmtTiempo(int? diasRestantes, int? minutosRestantes) {
  final m = minutosRestantes ?? (diasRestantes ?? 0) * 1440;
  if (m <= 0) return '0 minutos';
  if (m < 60) return '$m minuto${m != 1 ? 's' : ''}';
  if (m < 1440) {
    final h = (m / 60).round();
    return '$h hora${h != 1 ? 's' : ''}';
  }
  final d = (m / 1440).round();
  return '$d día${d != 1 ? 's' : ''}';
}

/// "$11.200 COP" a partir de centavos; "—" si no hay monto.
String fmtCOP(num? centavos) {
  if (centavos == null || centavos == 0) return '—';
  final s = (centavos / 100).round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '\$$buf COP';
}

const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sept',
  'oct',
  'nov',
  'dic',
];

/// "30 oct 2026" (como dateStyle: 'medium' en es-CO); "—" si no hay fecha.
String fmtFecha(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  return '${d.day} ${_meses[d.month - 1]} ${d.year}';
}

int? asInt(dynamic v) => v is num ? v.toInt() : null;
