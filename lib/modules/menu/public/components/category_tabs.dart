import 'package:flutter/material.dart' hide MenuTheme;
import '../models/public_menu_model.dart';

// Equivalente a src/components/CategoryTabs.jsx en React
// Tabs de categorías con scroll horizontal — sticky bajo el navbar

class CategoryTabs extends StatefulWidget {
  const CategoryTabs({
    super.key,
    required this.categories,
    required this.active,
    required this.onChanged,
    required this.theme,
  });

  final List<MenuCategory> categories;
  final String             active;
  final ValueChanged<String> onChanged;
  final MenuTheme          theme;

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  final _scrollCtrl = ScrollController();

  static const _iconMap = <String, IconData>{
    'all':    Icons.grid_view_outlined,   // "Todos" — equivale a LayoutGrid de lucide
    'burger': Icons.local_fire_department_outlined,
    'cup':    Icons.coffee_outlined,
    'cake':   Icons.cake_outlined,
    'ice':    Icons.icecream_outlined,
    'box':    Icons.inventory_2_outlined,
    'pizza':  Icons.local_pizza_outlined,
    'bag':    Icons.shopping_bag_outlined,
    'soup':   Icons.soup_kitchen_outlined,
    'star':   Icons.star_outline,
    'heart':  Icons.favorite_border,
  };

  @override
  void didUpdateWidget(CategoryTabs old) {
    super.didUpdateWidget(old);
    // Scroll hacia la tab activa (equivalente al useEffect de React)
    if (old.active != widget.active) {
      _scrollToActive();
    }
  }

  void _scrollToActive() {
    final idx = widget.categories.indexWhere((c) => c.id == widget.active);
    if (idx < 0 || !_scrollCtrl.hasClients) return;
    final itemWidth = 120.0;
    final target = (idx * itemWidth) - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);
    _scrollCtrl.animateTo(
      target.clamp(0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.categories.where((c) => c.isVisible).toList();

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.navBg,
        border: Border(bottom: BorderSide(color: widget.theme.navBorder)),
      ),
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: visible.map((cat) {
            final isActive = cat.id == widget.active;
            final icon     = _iconMap[cat.icon] ?? Icons.local_fire_department_outlined;

            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => widget.onChanged(cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? widget.theme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(widget.theme.buttonRadius),
                    border: Border.all(
                      color: isActive ? widget.theme.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14,
                          color: isActive ? Colors.white : widget.theme.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : widget.theme.textMuted,
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
}
