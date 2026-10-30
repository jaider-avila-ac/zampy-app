import 'package:flutter/material.dart';

import '../../../shared/app_colors.dart';
import '../models/explore_models.dart';
import 'acciones_tarjeta.dart';

// Equivalente a src/modules/explore/components/MenuCard.jsx en React

class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.menu,
    this.liked = false,
    this.conSesion = false,
    this.showActions = true,
    this.onTap,
    this.onToggleLike,
    this.onRequireLogin,
  });

  final TarjetaMenu menu;
  final bool liked;
  final bool conSesion;
  final bool showActions;
  final VoidCallback? onTap;
  final VoidCallback? onToggleLike;
  final VoidCallback? onRequireLogin;

  @override
  Widget build(BuildContext context) {
    final estado = _estado(menu.estado);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kCardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0E7FF)),
                ),
                clipBehavior: Clip.hardEdge,
                child: menu.logoUrl != null && menu.logoUrl!.isNotEmpty
                    ? Image.network(
                        menu.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => const Icon(
                          Icons.storefront_outlined,
                          color: Color(0xFFA5B4FC),
                          size: 24,
                        ),
                      )
                    : const Icon(
                        Icons.storefront_outlined,
                        color: Color(0xFFA5B4FC),
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      menu.nombreDisplay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextPrimary,
                      ),
                    ),
                    if (menu.categoria != null &&
                        menu.categoria!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        menu.categoria!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kBlueLight,
                        ),
                      ),
                    ],
                    if (menu.municipio != null &&
                        menu.municipio!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: AppColors.kTextMuted,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              menu.municipio!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.kTextMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (estado != null) ...[
                const SizedBox(width: 8),
                _EstadoBadge(texto: estado.$1, color: estado.$2),
              ],
              if (showActions) ...[
                const SizedBox(width: 4),
                AccionesTarjeta(
                  encanta: liked,
                  conSesion: conSesion,
                  onVerMas: onTap ?? () {},
                  onEncanta: onToggleLike ?? () {},
                  onRequireLogin: onRequireLogin ?? () {},
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  (String, Color)? _estado(String? estado) {
    switch (estado) {
      case 'publicado':
        return ('Publicado', const Color(0xFF047857));
      case 'borrador':
        return ('No publicado', AppColors.kTextMuted);
      case 'suspendido':
        return ('Suspendido', const Color(0xFFDC2626));
      default:
        return null;
    }
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
