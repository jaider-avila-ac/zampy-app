import 'package:flutter/material.dart';
import '../../../shared/app_colors.dart';
import '../models/menu_feed_item.dart';

/// Equivalente a MenuCard.jsx — tarjeta de menú en grilla 2 columnas.
/// Blanco, border slate-100, banner con image/placeholder + logo overlay.
class MenuCardWidget extends StatelessWidget {
  const MenuCardWidget({
    super.key,
    required this.menu,
    this.liked = false,
  });

  final MenuFeedItem menu;
  final bool liked;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner ────────────────────────────────────────────────────────
          SizedBox(
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBanner(),
                // Logo overlay — círculo bottom-left
                if (menu.logoUrl != null && menu.logoUrl!.isNotEmpty)
                  Positioned(
                    bottom: 6,
                    left: 10,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.white,
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Image.network(
                        menu.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.store_outlined,
                          size: 14,
                          color: AppColors.kTextMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── Contenido ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                Text(
                  menu.nombreNegocio,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextPrimary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Slogan
                if (menu.slogan != null && menu.slogan!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    menu.slogan!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.kTextMuted,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Footer: ciudad + likes
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (menu.ciudad != null && menu.ciudad!.isNotEmpty) ...[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 9,
                        color: AppColors.kTextMuted,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          menu.ciudad!,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.kTextMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (menu.meEncantas > 0 || liked) ...[
                      Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        size: 9,
                        color: liked ? AppColors.kBlue : AppColors.kTextMuted,
                      ),
                      if (menu.meEncantas > 0) ...[
                        const SizedBox(width: 2),
                        Text(
                          '${menu.meEncantas}',
                          style: TextStyle(
                            fontSize: 9,
                            color:
                                liked ? AppColors.kBlue : AppColors.kTextMuted,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    if (menu.bannerUrl != null && menu.bannerUrl!.isNotEmpty) {
      return Image.network(
        menu.bannerUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholderBanner(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _skeletonBanner(),
      );
    }
    return _placeholderBanner();
  }

  Widget _placeholderBanner() {
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

  Widget _skeletonBanner() => Container(color: AppColors.kSkeleton);
}
