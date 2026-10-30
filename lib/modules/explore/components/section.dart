import 'package:flutter/material.dart';

import '../../../shared/app_colors.dart';
import '../models/explore_models.dart';
import 'menu_card.dart';
import 'skeleton_menu_card.dart';

// Componente de sección horizontal reutilizable (equivalente a Section.jsx).
// Explore actual usa pestañas Menús/Platos; se conserva para otros listados.

class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.icon,
    required this.title,
    this.items,
    this.loading = false,
    this.likedIds = const {},
    this.conSesion = false,
    this.onCardTap,
    this.onToggleLike,
    this.onRequireLogin,
  });

  final IconData icon;
  final String title;
  final List<TarjetaMenu>? items;
  final bool loading;
  final Set<String> likedIds;
  final bool conSesion;
  final void Function(TarjetaMenu)? onCardTap;
  final void Function(TarjetaMenu)? onToggleLike;
  final VoidCallback? onRequireLogin;

  @override
  Widget build(BuildContext context) {
    if (!loading && (items == null || items!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: loading ? 3 : items!.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              if (loading) {
                return const SizedBox(width: 260, child: SkeletonMenuCard());
              }
              final item = items![index];
              return SizedBox(
                width: 290,
                child: MenuCard(
                  menu: item,
                  liked: likedIds.contains(item.codigo),
                  conSesion: conSesion,
                  onTap: onCardTap != null ? () => onCardTap!(item) : null,
                  onToggleLike: onToggleLike != null
                      ? () => onToggleLike!(item)
                      : null,
                  onRequireLogin: onRequireLogin,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
