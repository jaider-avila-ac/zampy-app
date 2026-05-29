class Dispositivo {
  final int id;
  final String? nombre;
  final String? ip;
  final DateTime? creadoEn;
  final bool esEste;
  final bool navegando;

  const Dispositivo({
    required this.id,
    this.nombre,
    this.ip,
    this.creadoEn,
    required this.esEste,
    required this.navegando,
  });

  factory Dispositivo.fromJson(Map<String, dynamic> j) => Dispositivo(
        id: (j['id'] as num).toInt(),
        nombre: j['nombre'] as String?,
        ip: j['ip'] as String?,
        creadoEn: j['creadoEn'] != null
            ? DateTime.tryParse(j['creadoEn'] as String)
            : null,
        esEste: j['esEste'] as bool? ?? false,
        navegando: j['navegando'] as bool? ?? false,
      );

  bool get isMobile {
    if (nombre == null) return false;
    final ua = nombre!.toLowerCase();
    return ua.contains('mobile') || ua.contains('android') || ua.contains('iphone');
  }

  String get browser {
    if (nombre == null) return 'Navegador';
    final ua = nombre!;
    if (ua.contains('Chrome') && !ua.contains('Edg')) return 'Chrome';
    if (ua.contains('Firefox')) return 'Firefox';
    if (ua.contains('Safari') && !ua.contains('Chrome')) return 'Safari';
    if (ua.contains('Edg')) return 'Edge';
    if (ua.contains('Opera') || ua.contains('OPR')) return 'Opera';
    return 'Navegador';
  }

  String get os {
    if (nombre == null) return '';
    final ua = nombre!;
    if (ua.contains('Windows')) return 'Windows';
    if (ua.contains('Mac OS')) return 'macOS';
    if (ua.contains('Android')) return 'Android';
    if (ua.contains('iPhone') || ua.contains('iPad')) return 'iOS';
    if (ua.contains('Linux')) return 'Linux';
    return '';
  }

  String get label {
    final o = os;
    return o.isNotEmpty ? '$browser · $o' : browser;
  }

  static String formatDate(DateTime? dt) {
    if (dt == null) return '';
    const m = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
                'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day.toString().padLeft(2, '0')} ${m[dt.month]} ${dt.year}, $h:$min';
  }
}
