import 'package:flutter/material.dart';
import '../../../shared/app_colors.dart';
import '../models/menu_feed_item.dart';
import 'menu_card_widget.dart';
import 'skeleton_card_widget.dart';

/// Equivalente a Section.jsx — ícono + título + grid 2 cols de MenuCard.
/// Si no está cargando y la lista está vacía, no renderiza nada.
class ExploreSectionWidget extends StatelessWidget {
  const ExploreSectionWidget({
    super.key,
    required this.icon,
    required this.title,
    this.items,
    this.loading = false,
    this.emptyMsg,
    this.likedIds = const {},
  });

  final IconData icon;
  final String title;
  final List<MenuFeedItem>? items;
  final bool loading;
  final String? emptyMsg;
  final Set<int> likedIds;

  @override
  Widget build(BuildContext context) {
    if (!loading && (items == null || items!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: ícono + título
        Row(
          children: [
            Icon(icon, size: 15, color: AppColors.kBlue),
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
        // Lista columna única
        Column(
          children: List.generate(
            loading ? 4 : items!.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: loading
                  ? const SkeletonCardWidget()
                  : MenuCardWidget(
                      menu: items![i],
                      liked: likedIds.contains(items![i].menId),
                    ),
            ),
          ),
        ),
        // Mensaje vacío
        if (!loading && (items?.isEmpty ?? true) && emptyMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              emptyMsg!,
              style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted),
            ),
          ),
      ],
    );
  }
}
