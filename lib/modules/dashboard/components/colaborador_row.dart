import 'package:flutter/material.dart';

import '../../../shared/app_colors.dart';
import '../models/dashboard_models.dart';

class ColaboradorRow extends StatelessWidget {
  const ColaboradorRow({super.key, required this.menu, required this.onOpen});

  final ColaboracionMenu menu;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final roleColor = menu.miRol == 'repartidor'
        ? const Color(0xFF64748B)
        : AppColors.kBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kCardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFF1F5F9),
                ),
                clipBehavior: Clip.hardEdge,
                child: menu.logoUrl != null && menu.logoUrl!.isNotEmpty
                    ? Image.network(
                        menu.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _LogoFallback(),
                      )
                    : const _LogoFallback(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.nombre.isNotEmpty ? menu.nombre : menu.slug,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (menu.slogan ?? '').trim().isNotEmpty
                          ? menu.slogan!
                          : 'Sin slogan',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.kTextMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Badge(
                    label: menu.publicado ? 'Publicado' : 'No publicado',
                    color: menu.publicado
                        ? AppColors.kBlue
                        : const Color(0xFF64748B),
                  ),
                  if (menu.miRol != null) ...[
                    const SizedBox(height: 4),
                    _Badge(label: menu.rolLabel, color: roleColor, light: true),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(color: Color(0xFF6366F1)),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.light = false});

  final String label;
  final Color color;
  final bool light;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: light ? color.withValues(alpha: 0.12) : color,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: light ? color : Colors.white,
      ),
    ),
  );
}
