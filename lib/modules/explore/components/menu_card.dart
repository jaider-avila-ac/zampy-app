import 'package:flutter/material.dart';
import '../../../shared/app_colors.dart';
import '../../menu/public/models/public_menu_model.dart';

// Equivalente a src/modules/explore/components/MenuCard.jsx en React
// Tarjeta de menú en el feed — replica el diseño móvil exacto de React

class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.menu,
    this.liked   = false,
    this.onTap,
    this.onToggleLike,
  });

  final MenuFeedItem  menu;
  final bool          liked;
  final VoidCallback? onTap;
  final VoidCallback? onToggleLike;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.kWhite,
          borderRadius: BorderRadius.circular(16), // rounded-2xl
          border: Border.all(color: AppColors.kCardBorder),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner — h-28 (112px) ──────────────────────────────────────
            SizedBox(
              height: 112,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen o gradiente fallback
                  if (menu.bannerUrl != null && menu.bannerUrl!.isNotEmpty)
                    Image.network(
                      menu.bannerUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, st) => _buildFallback(),
                    )
                  else
                    _buildFallback(),

                  // Logo superpuesto bottom-left (igual que React)
                  if (menu.logoUrl != null && menu.logoUrl!.isNotEmpty)
                    Positioned(
                      bottom: 6, left: 10,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: Image.network(
                            menu.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, st) =>
                                const Icon(Icons.store, size: 14, color: AppColors.kTextMuted),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Contenido — p-2.5 igual que React ─────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre — 2 líneas máx, h-8 (32px)
                  SizedBox(
                    height: 32,
                    child: Text(
                      menu.nombreNegocio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.kTextPrimary,
                        height: 1.33,
                      ),
                    ),
                  ),

                  // Slogan — 2 líneas, h-7 (28px)
                  SizedBox(
                    height: 28,
                    child: Text(
                      menu.slogan ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.kTextMuted,
                        height: 1.27,
                      ),
                    ),
                  ),

                  // Footer — ciudad + likes
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Ciudad
                      if (menu.ciudad != null && menu.ciudad!.isNotEmpty)
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 9, color: AppColors.kTextMuted),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  menu.ciudad!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.kTextMuted),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Spacer(),

                      // Likes
                      if (menu.meEncantas > 0 || liked)
                        GestureDetector(
                          onTap: onToggleLike,
                          child: Row(
                            children: [
                              Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                size: 9,
                                color: liked ? AppColors.kBlue : AppColors.kTextMuted,
                              ),
                              const SizedBox(width: 2),
                              if (menu.meEncantas > 0)
                                Text(
                                  _formatLikes(menu.meEncantas),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: liked ? AppColors.kBlue : AppColors.kTextMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0E7FF), Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          menu.iconoCategoria ?? '',
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  String _formatLikes(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
