import 'package:flutter/material.dart';
import '../../../shared/app_colors.dart';
import '../../../services/explore_service.dart';
import '../../menu/public/models/public_menu_model.dart';
import 'menu_card.dart';
import 'skeleton_card.dart';

// Equivalente a src/modules/explore/components/InfiniteExplorer.jsx en React
// Grid 2 columnas con scroll infinito cursor-based

class InfiniteExplorer extends StatefulWidget {
  const InfiniteExplorer({
    super.key,
    this.ciudad,
    this.excludeIds = const {},
    this.likedIds   = const {},
    this.onCardTap,
    this.onToggleLike,
  });

  final String?   ciudad;
  final Set<int>  excludeIds;
  final Set<int>  likedIds;
  final void Function(MenuFeedItem)? onCardTap;
  final void Function(MenuFeedItem)? onToggleLike;

  @override
  State<InfiniteExplorer> createState() => _InfiniteExplorerState();
}

class _InfiniteExplorerState extends State<InfiniteExplorer> {
  final List<MenuFeedItem> _items    = [];
  String?  _cursor;
  bool     _hasMore  = true;
  bool     _loading  = false;
  bool     _mounted  = false;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _loadMore();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final exclude = (_cursor == null && widget.excludeIds.isNotEmpty)
          ? widget.excludeIds.take(50).join(',')
          : null;

      final data = await ExploreService.getScroll(
        cursor:  _cursor,
        ciudad:  widget.ciudad,
        exclude: exclude,
      );

      if (!_mounted) return;

      if (data == null || (data['items'] as List?)?.isEmpty != false) {
        setState(() { _hasMore = false; _loading = false; });
        return;
      }

      final result = ScrollResult.fromJson(data);
      final seen   = <int>{..._items.map((m) => m.menId), ...widget.excludeIds};
      final newItems = result.items.where((m) => m.menId != 0 && !seen.contains(m.menId)).toList();

      setState(() {
        _items.addAll(newItems);
        _cursor  = result.nextCursor;
        _hasMore = result.hasMore && result.nextCursor != null;
        _loading = false;
      });
    } catch (_) {
      if (_mounted) setState(() { _hasMore = false; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && !_loading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado — Sparkles icon + "Explorador"
        const Row(
          children: [
            Icon(Icons.auto_awesome, size: 15, color: AppColors.kBlueLight),
            SizedBox(width: 8),
            Text(
              'Explorador',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.kTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Grid 2 columnas — equivalente a grid-cols-2 en React
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   2,
            crossAxisSpacing: 12,
            mainAxisSpacing:  12,
            childAspectRatio: 0.75,
          ),
          itemCount: _items.length + (_loading ? 4 : 0),
          itemBuilder: (_, i) {
            if (i >= _items.length) return const SkeletonCard();
            final item = _items[i];
            return MenuCard(
              menu:         item,
              liked:        widget.likedIds.contains(item.menId),
              onTap:        widget.onCardTap    != null ? () => widget.onCardTap!(item)    : null,
              onToggleLike: widget.onToggleLike != null ? () => widget.onToggleLike!(item) : null,
            );
          },
        ),

        // Sentinel para cargar más — NotificationListener lo activa
        if (_hasMore)
          _LoadMoreButton(onPressed: _loadMore),

        // Final del feed
        if (!_hasMore && _items.isNotEmpty)
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

// Botón invisible que dispara la carga cuando se hace visible
class _LoadMoreButton extends StatefulWidget {
  const _LoadMoreButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_LoadMoreButton> createState() => _LoadMoreButtonState();
}

class _LoadMoreButtonState extends State<_LoadMoreButton> {
  @override
  void initState() {
    super.initState();
    // Disparar la carga al aparecer en pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPressed();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 1);
}
