import 'package:flutter/material.dart';
import 'menu_publico_service.dart';
import 'models/menu_publico_model.dart';
import 'themes/theme_catalog.dart';
import 'widgets/category_tabs_bar.dart';
import 'widgets/menu_banner.dart';
import 'widgets/menu_navbar.dart';
import 'widgets/carousel_view.dart';
import 'widgets/product_card.dart';
import 'widgets/product_list_item.dart';
import 'widgets/product_modal.dart';
import 'widgets/theme_selector_panel.dart';

enum _ViewMode { grid, list, carousel }

/// Pantalla de menú público — equivalente a MenuPage.jsx (vista móvil).
/// Recibe [slug] para carga real o [isDemo] para el menú de demostración.
class PublicMenuScreen extends StatefulWidget {
  const PublicMenuScreen({super.key, this.slug, this.isDemo = false});

  final String? slug;
  final bool isDemo;

  @override
  State<PublicMenuScreen> createState() => _PublicMenuScreenState();
}

class _PublicMenuScreenState extends State<PublicMenuScreen> {
  MenuPublicoData? _data;
  bool _loading = true;
  String _error = '';

  String _activeCategory = '';
  String _searchQuery = '';
  _ViewMode _viewMode = _ViewMode.grid;

  // Demo theme selector state (equivalente a ThemeContext + ThemeSelector.jsx)
  String _selectedSkinId = 'fastfood';
  String? _selectedPaletteId;
  bool _themeSelectorOpen = false;

  ThemeSkin get _activeSkin =>
      kThemeCatalogById[_selectedSkinId] ?? kThemeCatalog.first;

  ThemePalette get _activePalette {
    final skin = _activeSkin;
    if (_selectedPaletteId == null) return skin.palettes.first;
    return skin.palettes.firstWhere(
      (p) => p.id == _selectedPaletteId,
      orElse: () => skin.palettes.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.isDemo) {
      // Intenta traer el tema del backend, así los colores vienen del servidor
      final demo = await MenuPublicoService.getDemoData();
      if (!mounted) return;
      setState(() {
        _data = demo;
        _loading = false;
        _activeCategory = demo.visibleCategories.firstOrNull?.id ?? '';
      });
      return;
    }
    if (widget.slug == null) {
      setState(() { _loading = false; _error = 'Slug no especificado'; });
      return;
    }
    final data = await MenuPublicoService.getPublicData(widget.slug!);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      _error = data == null ? 'No se pudo cargar el menú' : '';
      _activeCategory = data?.visibleCategories.firstOrNull?.id ?? '';
    });
  }

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  List<Producto> get _filtered {
    if (_data == null) return [];
    if (_isSearching) {
      final q = _searchQuery.toLowerCase();
      return _data!.visibleProducts.where((p) =>
          p.name.toLowerCase().contains(q) ||
          (p.description ?? '').toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }
    return _data!.productsForCategory(_activeCategory);
  }

  void _openModal(Producto p) {
    // En demo usamos el skin activo para el tema y el negocio
    final th       = widget.isDemo ? _activePalette.toMenuTheme() : _data!.theme;
    final business = widget.isDemo ? _activeSkin.business        : _data!.business;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductModal(
        product: p,
        theme: th,
        grupos: _data!.grupos,
        menuSlug: _data!.slug,
        business: business,
        isPublished: !widget.isDemo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading();
    if (_error.isNotEmpty) return _buildError();
    return _buildMenu();
  }

  // ── Loading ────────────────────────────────────────────────────────────────
  Widget _buildLoading() => Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      );

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError() => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant_menu_outlined,
                    size: 48, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 16),
                Text(_error,
                    style: const TextStyle(
                        fontSize: 15, color: Color(0xFF64748B)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );

  // ── Menú completo ──────────────────────────────────────────────────────────
  Widget _buildMenu() {
    final d  = _data!;

    // En demo: el skin activo controla colores y negocio; los productos/categorías
    // son siempre los del demo (igual que en MenuPage.jsx con datos estáticos).
    final th       = widget.isDemo ? _activePalette.toMenuTheme() : d.theme;
    final business = widget.isDemo ? _activeSkin.business        : d.business;

    final cats = d.visibleCategories;
    final isSinImagenes = cats
            .firstWhere((c) => c.id == _activeCategory,
                orElse: () => const MenuCategory(id: '', label: ''))
            .tipoContenido == 'sin_imagenes';

    // sin_imagenes fuerza lista (igual que JSX); carousel solo con imágenes
    final effectiveView = isSinImagenes ? _ViewMode.list : _viewMode;

    return Scaffold(
      backgroundColor: th.bg,
      body: Stack(
        children: [
          Column(
            children: [
              // Navbar sticky (fuera del scroll)
              MenuNavbar(
                business: business,
                theme: th,
                searchQuery: _searchQuery,
                onSearchChanged: (q) => setState(() => _searchQuery = q),
                onBack: () => Navigator.pop(context),
              ),

              // Todo lo demás scrollable con pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  color: th.primary,
                  child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Banner (solo si no busca)
                    if (!_isSearching)
                      SliverToBoxAdapter(
                        child: MenuBanner(
                          business: business,
                          theme: th,
                          surpriseProducts: d.visibleProducts,
                          onSurprise: _openModal,
                        ),
                      ),

                    // Category tabs sticky
                    if (!_isSearching && cats.isNotEmpty)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: CategoryTabsDelegate(
                          child: CategoryTabsBar(
                            categories: cats,
                            activeId: _activeCategory,
                            theme: th,
                            onChanged: (id) =>
                                setState(() => _activeCategory = id),
                          ),
                        ),
                      ),

                    // Sección header
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(th, effectiveView, isSinImagenes),
                    ),

                    // Productos
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: _buildProductSliver(effectiveView, th),
                    ),
                  ],
                  ),   // CustomScrollView
                ),     // RefreshIndicator
              ),       // Expanded
            ],
          ),

          // ThemeSelector flotante — solo en modo demo (equivalente a ThemeSelector.jsx)
          if (widget.isDemo)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              right: 16,
              child: ThemeSelectorPanel(
                open: _themeSelectorOpen,
                activeSkin: _activeSkin,
                activePalette: _activePalette,
                allSkins: kThemeCatalog,
                theme: th,
                onToggle: () =>
                    setState(() => _themeSelectorOpen = !_themeSelectorOpen),
                onSkinChanged: (skinId) => setState(() {
                  _selectedSkinId = skinId;
                  _selectedPaletteId = null;
                }),
                onPaletteChanged: (palId) =>
                    setState(() => _selectedPaletteId = palId),
              ),
            ),
        ],
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(
      MenuPublicoTheme th, _ViewMode effectiveView, bool isSinImagenes) {
    final cats = _data!.visibleCategories;
    final activeCat = cats.firstWhere(
        (c) => c.id == _activeCategory,
        orElse: () => const MenuCategory(id: '', label: ''));
    final label = _isSearching ? '"$_searchQuery"' : activeCat.label;
    final count = _filtered.length;
    final unit  = _isSearching ? 'resultados' : 'platos';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: th.text,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: th.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('$count $unit',
                style: TextStyle(fontSize: 11, color: th.textMuted)),
          ),
          const SizedBox(width: 8),
          // Toggle grid / list / carousel (solo si tiene imágenes — igual que JSX)
          if (!isSinImagenes)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: th.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: th.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ViewBtn(
                    icon: Icons.grid_view_rounded,
                    active: effectiveView == _ViewMode.grid,
                    theme: th,
                    onTap: () => setState(() => _viewMode = _ViewMode.grid),
                  ),
                  _ViewBtn(
                    icon: Icons.view_list_rounded,
                    active: effectiveView == _ViewMode.list,
                    theme: th,
                    onTap: () => setState(() => _viewMode = _ViewMode.list),
                  ),
                  _ViewBtn(
                    icon: Icons.view_carousel_rounded,
                    active: effectiveView == _ViewMode.carousel,
                    theme: th,
                    onTap: () => setState(() => _viewMode = _ViewMode.carousel),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Productos ──────────────────────────────────────────────────────────────
  Widget _buildProductSliver(_ViewMode mode, MenuPublicoTheme th) {
    final products = _filtered;

    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded,
                  size: 44,
                  color: th.textMuted.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('No se encontraron productos',
                  style: TextStyle(fontSize: 14, color: th.textMuted)),
            ],
          ),
        ),
      );
    }

    // Carrusel — envuelto en SliverToBoxAdapter (no es lazy, igual que JSX)
    if (mode == _ViewMode.carousel) {
      return SliverToBoxAdapter(
        child: MenuCarouselView(
          products: products,
          theme: th,
          onProductClick: _openModal,
        ),
      );
    }

    if (mode == _ViewMode.grid) {
      return SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) => ProductCard(
            product: products[i],
            theme: th,
            onTap: () => _openModal(products[i]),
          ),
          childCount: products.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 280,
        ),
      );
    }

    // Lista
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ProductListItem(
            product: products[i],
            theme: th,
            onTap: () => _openModal(products[i]),
          ),
        ),
        childCount: products.length,
      ),
    );
  }
}

// ── Botón modo vista ──────────────────────────────────────────────────────────

class _ViewBtn extends StatelessWidget {
  const _ViewBtn({
    required this.icon,
    required this.active,
    required this.theme,
    required this.onTap,
  });
  final IconData icon;
  final bool active;
  final MenuPublicoTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: active ? theme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon,
              size: 14,
              color: active ? Colors.white : theme.textMuted),
        ),
      );
}
