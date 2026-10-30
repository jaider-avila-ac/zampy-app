import 'package:flutter/material.dart';

import '../../../shared/app_colors.dart';
import '../models/dashboard_models.dart';

class MenuSteps extends StatelessWidget {
  const MenuSteps({super.key, required this.pasos, required this.onTap});

  final List<PasoMenu> pasos;
  final ValueChanged<PasoMenu> onTap;

  static const _meta = <String, (String, IconData)>{
    'imagenes': ('Logo y portada', Icons.image_outlined),
    'ubicacion': ('Ubicación del local', Icons.location_on_outlined),
    'contacto': ('Teléfono, WhatsApp o correo', Icons.phone_outlined),
    'productos': ('Categorías y productos', Icons.restaurant_menu_outlined),
    'horario': ('Horario de atención', Icons.access_time_outlined),
    'redes': ('Redes sociales', Icons.share_outlined),
    'galeria': ('Galería del local', Icons.photo_library_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final conocidos = pasos
        .where((p) => _meta.containsKey(p.codigo))
        .toList(growable: false);
    final hechos = conocidos.where((p) => p.completo).length;
    if (conocidos.isEmpty || hechos == conocidos.length) {
      return const SizedBox.shrink();
    }
    final faltanObligatorios = conocidos.any(
      (p) => p.obligatorio && !p.completo,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Completa tu menú',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.kTextPrimary,
                  ),
                ),
              ),
              Text(
                '$hechos de ${conocidos.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: conocidos.isEmpty ? 0 : hechos / conocidos.length,
              minHeight: 6,
              color: AppColors.kBlue,
              backgroundColor: AppColors.kSkeleton,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            faltanObligatorios
                ? 'Lo marcado como necesario se pide para publicar.'
                : 'Ya puedes publicar; lo demás ayuda a que te encuentren.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.kTextMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < conocidos.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
            _StepRow(
              paso: conocidos[i],
              meta: _meta[conocidos[i].codigo]!,
              onTap: () => onTap(conocidos[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.paso, required this.meta, required this.onTap});

  final PasoMenu paso;
  final (String, IconData) meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hecha = paso.completo;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          children: [
            Icon(
              hecha ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: hecha ? AppColors.kBlue : AppColors.kTextMuted,
            ),
            const SizedBox(width: 10),
            Icon(meta.$2, size: 15, color: AppColors.kTextMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                meta.$1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hecha ? FontWeight.w400 : FontWeight.w600,
                  color: hecha ? AppColors.kTextMuted : AppColors.kTextPrimary,
                  decoration: hecha ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (paso.obligatorio && !hecha)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Necesario',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.kTextMuted,
            ),
          ],
        ),
      ),
    );
  }
}
