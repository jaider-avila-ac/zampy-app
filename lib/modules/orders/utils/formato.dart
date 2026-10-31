// Formatos compartidos del módulo de pedidos (equivalen a fmtPrice y bogotaHoy de React).

/// $12.345 (pesos, sin decimales, separador de miles con punto).
String precio(num? v) {
  final n = (v ?? 0).round();
  final s = n.abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '\$$buf';
}

/// 14:05 en la hora local del dispositivo.
String hora(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// yyyy-MM-dd
String fechaIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// La fecha de hoy en Bogotá (UTC−5 todo el año, sin horario de verano): el negocio filtra por su día, no por el
/// del dispositivo.
String bogotaHoy([DateTime? ahora]) =>
    fechaIso((ahora ?? DateTime.now()).toUtc().subtract(const Duration(hours: 5)));

/// 30 oct 2026 a partir de yyyy-MM-dd.
String fechaCorta(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  const m = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}
