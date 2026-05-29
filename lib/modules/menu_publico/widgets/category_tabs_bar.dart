import 'package:flutter/material.dart';
import '../models/menu_publico_model.dart';

/// Equivalente a CategoryTabs.jsx — tabs horizontales scrollables sticky.
class CategoryTabsBar extends StatefulWidget {
  const CategoryTabsBar({
    super.key,
    required this.categories,
    required this.activeId,
    required this.theme,
    required this.onChanged,
  });

  final List<MenuCategory> categories;
  final String activeId;
  final MenuPublicoTheme theme;
  final ValueChanged<String> onChanged;

  @override
  State<CategoryTabsBar> createState() => _CategoryTabsBarState();
}

class _CategoryTabsBarState extends State<CategoryTabsBar> {
  final _scroll = ScrollController();
  final _keys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    for (final cat in widget.categories) {
      _keys[cat.id] = GlobalKey();
    }
  }

  @override
  void didUpdateWidget(CategoryTabsBar old) {
    super.didUpdateWidget(old);
    if (old.activeId != widget.activeId) {
      _scrollToActive();
    }
  }

  void _scrollToActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _keys[widget.activeId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.navBg,
        border: Border(bottom: BorderSide(color: theme.navBorder)),
      ),
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: widget.categories.map((cat) {
            final isActive = cat.id == widget.activeId;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                key: _keys[cat.id],
                onTap: () => widget.onChanged(cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? theme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? theme.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconFor(cat.icon),
                        size: 14,
                        color: isActive
                            ? Colors.white
                            : theme.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  static IconData _iconFor(String? icon) {
    switch (icon) {
      case 'burger':  return Icons.local_fire_department_outlined;
      case 'cup':     return Icons.coffee_outlined;
      case 'cake':    return Icons.cake_outlined;
      case 'ice':     return Icons.icecream_outlined;
      case 'box':     return Icons.inventory_2_outlined;
      case 'pizza':   return Icons.local_pizza_outlined;
      case 'bag':     return Icons.shopping_bag_outlined;
      case 'soup':    return Icons.soup_kitchen_outlined;
      case 'star':    return Icons.star_outline;
      case 'heart':   return Icons.favorite_outline;
      default:        return Icons.restaurant_outlined;
    }
  }
}

/// Delegate para SliverPersistentHeader (sticky).
class CategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  const CategoryTabsDelegate({required this.child});
  final Widget child;

  @override double get minExtent => 52;
  @override double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      child;

  @override
  bool shouldRebuild(CategoryTabsDelegate old) => old.child != child;
}
