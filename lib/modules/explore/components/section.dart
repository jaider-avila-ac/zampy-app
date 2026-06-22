import 'package:flutter/material.dart';
import '../../../shared/app_colors.dart';
import '../../menu/public/models/public_menu_model.dart';
import 'menu_card.dart';
import 'skeleton_card.dart';

// Equivalente a src/modules/explore/components/Section.jsx en React
// Sección con scroll horizontal de tarjetas de menú

class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.icon,
    required this.title,
    this.items,
    this.loading   = false,
    this.emptyMsg,
    this.likedIds  = const {},
    this.onCardTap,
    this.onToggleLike,
  });

  final IconData            icon;
  final String              title;
  final List<MenuFeedItem>? items;
  final bool                loading;
  final String?             emptyMsg;
  final Set<int>            likedIds;
  final void Function(MenuFeedItem)? onCardTap;
  final void Function(MenuFeedItem)? onToggleLike;

  @override
  Widget build(BuildContext context) {
    // Si no hay contenido y no está cargando, no renderizar nada (igual que React)
    if (!loading && (items == null || items!.isEmpty)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Encabezado con ícono — igual que Section.jsx ─────────────────
        Row(
          children: [
            Icon(icon, size: 15, color: AppColors.kBlueLight),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.kTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Lista horizontal con scroll — equivalente al div overflow-x-auto ──
        SizedBox(
          height: 220, // altura total de MenuCard (112 banner + 108 contenido)
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: loading ? 6 : items!.length,
            separatorBuilder: (_, i) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              if (loading) {
                return const SizedBox(width: 160, child: SkeletonCard());
              }
              final item = items![i];
              return SizedBox(
                width: 160, // w-40 = 160px igual que React
                child: MenuCard(
                  menu:          item,
                  liked:         likedIds.contains(item.menId),
                  onTap:         onCardTap != null ? () => onCardTap!(item)       : null,
                  onToggleLike:  onToggleLike != null ? () => onToggleLike!(item) : null,
                ),
              );
            },
          ),
        ),

        // Mensaje vacío
        if (!loading && (items?.isEmpty ?? true) && emptyMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              emptyMsg!,
              style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
            ),
          ),
      ],
    );
  }
}
