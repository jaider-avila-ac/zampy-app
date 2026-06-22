import 'package:flutter/material.dart' hide MenuTheme, Banner;
import '../modules/menu/public/models/public_menu_model.dart';
import '../modules/menu/public/components/banner.dart';
import '../modules/menu/public/components/category_tabs.dart';
import '../modules/menu/public/components/product_card.dart';
import '../modules/menu/public/components/product_list_item.dart';
import '../modules/menu/public/components/product_modal.dart';
import '../modules/menu/public/components/reviews_section.dart';
import '../modules/menu/public/components/footer.dart';
import '../services/interaccion_service.dart';

// Equivalente a src/components/MenuPage.jsx en React
// Componente principal que renderiza el menú completo en móvil

enum _ViewMode { grid, list }

class MenuPage extends StatefulWidget {
  const MenuPage({
    super.key,
    required this.menuData,
    this.menuSlug,
    this.isPublished = false,
  });

  final PublicMenuData menuData;
  final String?        menuSlug;
  final bool           isPublished;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String       _activeCategory = '';
  _ViewMode    _viewMode       = _ViewMode.grid;
  String       _searchQuery    = '';
  List<ReviewModel> _reviews   = [];

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.menuData.categories.firstOrNull?.id ?? '';
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    if (widget.menuSlug == null) return;
    // Resumen (equivalente a getResumen en React)
    await InteraccionService.getResumen(widget.menuSlug!);
    // Reseñas
    final rawReviews = await InteraccionService.getResenas(widget.menuSlug!);
    if (mounted) {
      setState(() {
        _reviews = rawReviews
            .whereType<Map<String, dynamic>>()
            .map(ReviewModel.fromJson)
            .toList();
      });
    }
  }

  List<MenuProduct> get _filteredProducts {
    final data = widget.menuData;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      return data.products.where((p) =>
          p.name.toLowerCase().contains(q) ||
          (p.description ?? '').toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }
    return data.productsForCategory(_activeCategory);
  }

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  void _openProduct(MenuProduct product) {
    ProductModal.show(context, product, widget.menuData.theme);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.menuData.theme;
    final cats  = widget.menuData.categories;

    return Container(
      color: theme.bg,
      child: CustomScrollView(
        slivers: [
          // ── Banner del restaurante ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Banner(info: widget.menuData.info, theme: theme),
          ),

          // ── Barra de búsqueda de productos ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _ProductSearchBar(
                value:     _searchQuery,
                theme:     theme,
                onChanged: (v) => setState(() => _searchQuery = v),
                onClear:   () => setState(() => _searchQuery = ''),
              ),
            ),
          ),

          // ── Category Tabs — sticky ─────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabsDelegate(
              child: CategoryTabs(
                categories: cats,
                active:     _activeCategory,
                onChanged:  (id) => setState(() { _activeCategory = id; _searchQuery = ''; }),
                theme:      theme,
              ),
            ),
          ),

          // ── Controles de vista (grid / lista) ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: _ViewToggle(
                mode:      _viewMode,
                theme:     theme,
                onChanged: (m) => setState(() => _viewMode = m),
              ),
            ),
          ),

          // ── Grid o Lista de productos ──────────────────────────────────
          if (_viewMode == _ViewMode.grid)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:   2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing:  12,
                  childAspectRatio: 280 / 280, // altura fija 280 igual que React
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductCard(
                    product: _filteredProducts[i],
                    theme:   theme,
                    onTap:   () => _openProduct(_filteredProducts[i]),
                  ),
                  childCount: _filteredProducts.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductListItem(
                    product: _filteredProducts[i],
                    theme:   theme,
                    onTap:   () => _openProduct(_filteredProducts[i]),
                  ),
                  childCount: _filteredProducts.length,
                ),
              ),
            ),

          // ── Mensaje si no hay productos ────────────────────────────────
          if (_filteredProducts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    _isSearching
                        ? 'Sin resultados para "$_searchQuery"'
                        : 'Sin productos en esta categoría',
                    style: TextStyle(fontSize: 13, color: theme.textMuted),
                  ),
                ),
              ),
            ),

          // ── Reseñas ───────────────────────────────────────────────────
          if (_reviews.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                child: ReviewsSection(reviews: _reviews, theme: theme),
              ),
            ),

          // ── Footer ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: MenuFooter(theme: theme)),
        ],
      ),
    );
  }
}

// ── Barra de búsqueda de productos ────────────────────────────────────────────
class _ProductSearchBar extends StatefulWidget {
  const _ProductSearchBar({
    required this.value,
    required this.theme,
    required this.onChanged,
    required this.onClear,
  });

  final String   value;
  final MenuTheme theme;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<_ProductSearchBar> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.value;
  }

  @override
  void didUpdateWidget(_ProductSearchBar old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) _ctrl.text = widget.value;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        decoration: BoxDecoration(
          color: widget.theme.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.theme.border),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.search, size: 15, color: widget.theme.textMuted),
            ),
            Expanded(
              child: TextField(
                controller: _ctrl,
                onChanged: widget.onChanged,
                style: TextStyle(fontSize: 13, color: widget.theme.text),
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
                  hintStyle: TextStyle(fontSize: 13, color: widget.theme.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (widget.value.isNotEmpty)
              GestureDetector(
                onTap: () { _ctrl.clear(); widget.onClear(); },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.close, size: 14, color: widget.theme.textMuted),
                ),
              ),
          ],
        ),
      );
}

// ── Toggle grid/lista ─────────────────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.mode, required this.theme, required this.onChanged});
  final _ViewMode   mode;
  final MenuTheme   theme;
  final ValueChanged<_ViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _Btn(
          icon: Icons.grid_view_outlined,
          active: mode == _ViewMode.grid,
          theme: theme,
          onTap: () => onChanged(_ViewMode.grid),
        ),
        const SizedBox(width: 6),
        _Btn(
          icon: Icons.list_outlined,
          active: mode == _ViewMode.list,
          theme: theme,
          onTap: () => onChanged(_ViewMode.list),
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.active, required this.theme, required this.onTap});
  final IconData  icon;
  final bool      active;
  final MenuTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? theme.primary : theme.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.border),
          ),
          child: Icon(icon, size: 16,
              color: active ? Colors.white : theme.textMuted),
        ),
      );
}

// ── Delegate para sticky CategoryTabs ────────────────────────────────────────
class _StickyTabsDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabsDelegate({required this.child});
  final Widget child;

  @override double get minExtent => 52;
  @override double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_StickyTabsDelegate old) => old.child != child;
}
