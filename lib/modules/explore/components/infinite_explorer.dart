import 'package:flutter/material.dart';

import '../../../shared/app_colors.dart';
import '../models/explore_models.dart';
import 'menu_card.dart';
import 'skeleton_menu_card.dart';

// Equivalente a src/modules/explore/components/InfiniteExplorer.jsx en React.
// La carga de páginas la controla ExploreController; este widget solo pinta el estado.

class InfiniteExplorer extends StatelessWidget {
  const InfiniteExplorer({
    super.key,
    required this.items,
    required this.loading,
    required this.hasMore,
    required this.likedIds,
    required this.conSesion,
    required this.onTap,
    required this.onToggleLike,
    required this.onRequireLogin,
    this.error,
    this.onRetry,
  });

  final List<TarjetaMenu> items;
  final bool loading;
  final bool hasMore;
  final Set<String> likedIds;
  final bool conSesion;
  final String? error;
  final VoidCallback? onRetry;
  final void Function(TarjetaMenu) onTap;
  final void Function(TarjetaMenu) onToggleLike;
  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !loading && error == null) {
      return const _EmptyExplore(
        title: 'Aún no hay menús publicados',
        subtitle: 'Sé el primero en publicar el tuyo.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null && items.isEmpty)
          _ErrorState(message: error!, onRetry: onRetry)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width >= 1000
                  ? 3
                  : MediaQuery.sizeOf(context).width >= 700
                  ? 2
                  : 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 92,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final menu = items[index];
              return MenuCard(
                menu: menu,
                liked: likedIds.contains(menu.codigo),
                conSesion: conSesion,
                onTap: () => onTap(menu),
                onToggleLike: () => onToggleLike(menu),
                onRequireLogin: onRequireLogin,
              );
            },
          ),
        if (loading)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: SkeletonMenuCard(),
          ),
        if (!loading && hasMore && items.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (!hasMore && items.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Ya viste todo el explorador',
                style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyExplore extends StatelessWidget {
  const _EmptyExplore({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
