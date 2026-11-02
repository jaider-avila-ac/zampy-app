import 'package:flutter/material.dart';
import '../models/logro_model.dart';
import '../../../../shared/app_colors.dart';

// Equivalente a LogroCard.jsx + ProgressBar.jsx

// Mapa condicion → ícono + label (equivalente a CONDICION_META en React)
({IconData icon, String label}) _condicionMeta(String condicion) =>
    switch (condicion) {
      'ME_ENCANTAS'  => (icon: Icons.favorite_outline,   label: 'me encantas'),
      'VISITAS'      => (icon: Icons.visibility_outlined, label: 'visitas'),
      'RESENAS'      => (icon: Icons.message_outlined,    label: 'reseñas'),
      'INVITACIONES' => (icon: Icons.group_outlined,      label: 'invitaciones completadas'),
      _              => (icon: Icons.emoji_events_outlined, label: condicion),
    };

// Formateo numérico estilo es-CO: 1000 → 1.000
String _fmt(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

// Formateo de fecha ISO → "15 ene. 2024"
String? _fmtDate(String? iso) {
  if (iso == null) return null;
  try {
    final d = DateTime.parse(iso).toLocal();
    const m = ['ene', 'feb', 'mar', 'abr', 'may', 'jun',
                'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${d.day} ${m[d.month - 1]}. ${d.year}';
  } catch (_) {
    return null;
  }
}

class LogroCard extends StatelessWidget {
  const LogroCard({
    super.key,
    required this.logro,
    this.selectable = false,
    this.selected = false,
    this.onSelect,
    this.menuNombre,
  });

  final LogroModel logro;
  // Recompensa DISPONIBLE: se puede marcar para aplicarla a un menú.
  final bool selectable;
  final bool selected;
  final VoidCallback? onSelect;
  // Nombre del menú donde se aplicó (si es uno propio).
  final String? menuNombre;

  @override
  Widget build(BuildContext context) {
    final meta   = _condicionMeta(logro.condicion);
    final faltan = (logro.cantidad - logro.progreso).clamp(0, logro.cantidad);
    final pct    = logro.cantidad > 0
        ? (logro.progreso / logro.cantidad).clamp(0.0, 1.0)
        : 0.0;
    final borderColor = selected
        ? const Color(0xFFA5B4FC)   // indigo-300
        : logro.desbloqueado
        ? const Color(0xFFA5B4FC)   // indigo-300 (como React: border-indigo-300)
        : AppColors.kCardBorder;    // slate-200

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        border:       Border.all(color: borderColor, width: selected ? 2 : 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: ícono + nombre/descripción + badge días
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectable)
                SizedBox(
                  width: 28,
                  height: 24,
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => onSelect?.call(),
                    activeColor: AppColors.kBlue,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(meta.icon, size: 18, color: AppColors.kBlueLight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      logro.nombre,
                      style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      AppColors.kTextPrimary,
                        height:     1.25,
                      ),
                    ),
                    if (logro.descripcion != null && logro.descripcion!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          logro.descripcion!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.kTextMuted),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge "+X días"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        AppColors.kBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${logro.diasRecompensa} días',
                  style: const TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color:      Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Estado: desbloqueado o barra de progreso
          if (logro.desbloqueado)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 13, color: Color(0xFF4F46E5)), // emerald-600
                const SizedBox(width: 4),
                Text(
                  logro.aplicado ? 'Aplicado' : 'Disponible',
                  style: const TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color:      Color(0xFF4F46E5),
                  ),
                ),
                if (_fmtDate(logro.desbloqueadoEn) != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '· ${_fmtDate(logro.desbloqueadoEn)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.kTextMuted),
                  ),
                ],
                if (logro.aplicado && menuNombre != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '· $menuNombre',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.kTextMuted),
                  ),
                ],
              ],
            )
          else
            Column(
              children: [
                // Barra de progreso (equivalente a ProgressBar.jsx)
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 6,
                    child: LinearProgressIndicator(
                      value:           pct,
                      backgroundColor: AppColors.kSkeleton,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.kBlueLight),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Progreso texto
                Row(
                  children: [
                    Icon(meta.icon, size: 11, color: AppColors.kTextMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${_fmt(logro.progreso)} / ${_fmt(logro.cantidad)} ${meta.label}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.kTextMuted),
                      ),
                    ),
                    Text(
                      faltan > 0 ? 'Faltan ${_fmt(faltan)}' : '¡Listo!',
                      style: const TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                        color:      AppColors.kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
