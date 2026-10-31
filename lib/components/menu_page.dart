import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide MenuTheme, Banner, CarouselView;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../context/cart_context.dart';
import '../modules/menu/public/components/cart_sheet.dart';
import '../modules/menu/public/edicion/edicion_menu.dart';
import '../modules/menu/public/edicion/producto/producto_editable.dart';

import '../modules/menu/public/models/public_menu_model.dart';
import '../modules/menu/public/components/banner.dart';
import '../modules/menu/public/components/category_tabs.dart';
import '../modules/menu/public/components/product_card.dart';
import '../modules/menu/public/components/product_list_item.dart';
import '../modules/menu/public/components/product_modal.dart';
import '../modules/menu/public/components/carousel_view.dart';
import '../modules/menu/public/components/reviews_section.dart';
import '../modules/menu/public/components/footer.dart';
import '../modules/menu/public/components/share_modal.dart';
import '../services/estadisticas_service.dart';
import '../services/interaccion_service.dart';

// Equivalente a src/modules/menu/public/components/MenuPage.jsx en React
// Incluye Navbar, Banner, CategoryTabs, productos, reseñas y footer

enum _View { grid, list, carousel }

const _kAllId = '__all__';

class MenuPage extends StatefulWidget {
  const MenuPage({
    super.key,
    required this.menuData,
    this.menuSlug,
    this.menuCodigo,
    this.isPublished = false,
    this.showQrButton,
    this.staffMode = false,
    this.esPropio = false,
    this.initialProductId,
  });

  final PublicMenuData menuData;
  final String? menuSlug;
  final String? menuCodigo;
  final bool isPublished;
  final bool? showQrButton;
  final bool staffMode;
  final bool esPropio;
  final String? initialProductId;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String _activeCategory = _kAllId;
  _View _viewMode = _View.grid;
  bool _searchOpen = false;
  String _searchQuery = '';
  int _meEncantas = 0;
  Timer? _viewTimer;

  final _searchCtrl = TextEditingController();

  // Categorías con "Todos" al inicio — igual que React
  List<MenuCategory> get _allCategories => [
    const MenuCategory(id: _kAllId, name: 'Todos', icon: 'all'),
    ...widget.menuData.categories,
  ];

  bool get _isSearching => _searchQuery.trim().isNotEmpty;
  bool get _isAllMode => _activeCategory == _kAllId && !_isSearching;

  int get _gridColumns {
    final width = MediaQuery.sizeOf(context).width;
    return (width / 180).floor().clamp(2, 6);
  }

  int get _listColumns => MediaQuery.sizeOf(context).width >= 700 ? 2 : 1;

  MenuCategory? get _activeCat => widget.menuData.categories
      .where((c) => c.id == _activeCategory)
      .firstOrNull;

  String get _activeCatType => _activeCat?.tipoContenido ?? 'con_imagenes';

  _View get _activeView {
    if (!_isAllMode && _activeCatType == 'sin_imagenes') return _View.list;
    return _viewMode;
  }

  String get _sectionTitle {
    if (_isSearching) return '"$_searchQuery"';
    if (_isAllMode) return 'Todo el menú';
    return _activeCat?.name ?? '';
  }

  List<MenuProduct> get _filteredProducts {
    if (_isSearching) {
      final q = _searchQuery.toLowerCase();
      return widget.menuData.products
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                (p.description ?? '').toLowerCase().contains(q) ||
                p.tags.any((t) => t.toLowerCase().contains(q)),
          )
          .toList();
    }
    if (_activeCategory == _kAllId) return widget.menuData.products;
    return widget.menuData.productsForCategory(_activeCategory);
  }

  // Agrupados por categoría para modo "Todos" grid/list
  List<({MenuCategory cat, List<MenuProduct> items})> get _groupedProducts {
    return widget.menuData.categories
        .map(
          (cat) =>
              (cat: cat, items: widget.menuData.productsForCategory(cat.id)),
        )
        // editando: también las vacías, para agregarles productos
        .where((g) => EdicionMenu.of(context) != null || g.items.isNotEmpty)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadResumen();

    if (widget.isPublished && widget.menuSlug != null && !widget.staffMode) {
      _viewTimer = Timer(const Duration(seconds: 5), () {
        EstadisticasService.registrarVistaMenu(widget.menuSlug!);
      });
    }

    // Carrito del menú (guardado en el servidor), como initMenu de CartContext en React.
    if (_pedidosActivos) {
      final info = widget.menuData.info;
      context.read<CartContext>().initMenu(widget.menuCodigo!, widget.menuSlug, info.whatsapp, info.name);
    }

    final initialId = widget.initialProductId;
    if (initialId != null && initialId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final product = widget.menuData.products
            .where((p) => p.id == initialId)
            .firstOrNull;
        if (product != null) _openProduct(product);
      });
    }
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openProduct(MenuProduct product) {
    ProductModal.show(
      context,
      product,
      widget.menuData.theme,
      menuSlug: widget.menuSlug,
      menuCodigo: widget.menuCodigo,
      info: widget.menuData.info,
      grupos: widget.menuData.grupos,
      trackView: widget.isPublished && !widget.staffMode,
      staffMode: widget.staffMode,
      esPropio: widget.esPropio,
    );
  }

  Future<void> _loadResumen() async {
    if (widget.menuSlug == null) return;
    final data = await InteraccionService.getResumen(widget.menuSlug!);
    if (mounted && data != null) {
      setState(() => _meEncantas = (data['meEncantas'] as num?)?.toInt() ?? 0);
    }
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchQuery = '';
        _searchCtrl.clear();
      }
    });
  }

  void _changeCategory(String id) {
    setState(() {
      _activeCategory = id;
      _searchQuery = '';
      _searchCtrl.clear();
      _searchOpen = false;
      if (_activeCatType == 'sin_imagenes') _viewMode = _View.list;
    });
  }

  // Equivalente a SurpriseButton.jsx — abre un producto aleatorio
  void _surprise() {
    final products = widget.menuData.products;
    if (products.isEmpty) return;
    final random = products[math.Random().nextInt(products.length)];
    _openProduct(random);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.menuData.theme;
    final info = widget.menuData.info;

    return Stack(
      children: [
        _contenido(theme, info),
        if (_pedidosActivos) _botonCarrito(theme),
      ],
    );
  }

  bool get _pedidosActivos =>
      widget.isPublished &&
      !widget.staffMode &&
      widget.menuCodigo != null &&
      widget.menuData.info.pedidosActivos;

  // Botón flotante con la cantidad de productos del carrito.
  Widget _botonCarrito(MenuTheme theme) {
    final count = context.watch<CartContext>().count;
    if (count == 0) return const SizedBox.shrink();
    return Positioned(
      right: 16,
      bottom: 16 + MediaQuery.of(context).padding.bottom,
      child: FloatingActionButton.extended(
        heroTag: 'carrito',
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        onPressed: () => CartSheet.show(
          context,
          menuCodigo: widget.menuCodigo!,
          theme: theme,
          info: widget.menuData.info,
        ),
        icon: const Icon(Icons.shopping_cart_outlined),
        label: Text('Carrito · $count'),
      ),
    );
  }

  Widget _contenido(MenuTheme theme, MenuInfo info) {
    return Container(
      color: theme.bg,
      child: CustomScrollView(
        slivers: [
          // ── Navbar sticky (equivale a <Navbar> en React) ─────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            automaticallyImplyLeading: false,
            toolbarHeight: 56,
            backgroundColor: theme.navBg,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: theme.navBorder),
            ),
            // editando: el menú de edición en la cabecera (MenuHamburguesa)
            actions: [
              if (EdicionMenu.of(context)?.encabezado case final encabezado?)
                Padding(padding: const EdgeInsets.only(right: 8), child: encabezado),
            ],
            title: _NavbarRow(
              info: info,
              theme: theme,
              searchOpen: _searchOpen,
              searchCtrl: _searchCtrl,
              onToggle: _toggleSearch,
              onSearchChange: (v) => setState(() => _searchQuery = v),
              onQr: (widget.showQrButton ?? widget.menuSlug != null)
                  ? (widget.menuSlug != null
                        ? () =>
                              ShareModal.show(context, widget.menuSlug!, theme)
                        : () {}) // icono visible pero sin acción (ej: preview)
                  : null,
            ),
          ),

          // ── Banner (solo cuando no se busca) ─────────────────────────
          if (!_isSearching)
            SliverToBoxAdapter(
              child: Banner(
                info: info,
                theme: theme,
                horario: widget.menuData.horario,
              ),
            ),

          // ── Category tabs sticky bajo el Navbar ───────────────────────
          if (!_isSearching)
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabDelegate(
                child: CategoryTabs(
                  categories: _allCategories,
                  active: _activeCategory,
                  onChanged: _changeCategory,
                  theme: theme,
                ),
              ),
            ),

          if (!_isSearching &&
              _isAllMode &&
              widget.menuData.featuredProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: _FeaturedRow(
                products: widget.menuData.featuredProducts,
                theme: theme,
                onTap: _openProduct,
              ),
            ),

          // ── Header de sección: título + línea + count + toggle ────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Text(
                    _sectionTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Divider(color: theme.border, height: 1)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.surfaceAlt,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${_filteredProducts.length} ${_isSearching ? "resultados" : "platos"}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón Aleatorio — equivale a SurpriseButton.jsx en React
                  if (widget.menuData.products.isNotEmpty)
                    GestureDetector(
                      onTap: _surprise,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: theme.primary.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Icon(
                          Icons.shuffle,
                          size: 15,
                          color: theme.primary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  // Toggle de vistas. React deja solo "Lista" cuando la
                  // categoría activa es sin_imagenes.
                  _ViewToggle(
                    view: _activeCatType == 'sin_imagenes'
                        ? _View.list
                        : _viewMode,
                    theme: theme,
                    onlyList: _activeCatType == 'sin_imagenes',
                    onChanged: (v) => setState(() => _viewMode = v),
                  ),
                ],
              ),
            ),
          ),

          // ── Productos ─────────────────────────────────────────────────
          ..._buildProductSlivers(theme),

          // ── Reseñas ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: ReviewsSection(
              theme: theme,
              menuSlug: widget.menuSlug,
              menuCodigo: widget.menuCodigo,
              meEncantas: _meEncantas,
              esPropio: widget.esPropio,
              staffMode: widget.staffMode,
            ),
          ),

          // ── Footer ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: MenuFooter(info: info, theme: theme),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductSlivers(MenuTheme theme) {
    final products = _filteredProducts;

    // ── Estado vacío ──────────────────────────────────────────────────
    if (products.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_outlined,
                  size: 44,
                  color: theme.textMuted.withValues(alpha: 0.22),
                ),
                const SizedBox(height: 10),
                Text(
                  'No se encontraron productos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.textMuted,
                  ),
                ),
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Intenta con otro término',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textMuted.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ];
    }

    if (_isSearching) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _listColumns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 0,
              mainAxisExtent: 140,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _fila(products[i], theme),
              ),
              childCount: products.length,
            ),
          ),
        ),
      ];
    }

    // ── Carrusel (cualquier modo: todos o categoría individual) ───────
    if (_activeView == _View.carousel) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: CarouselView(
              products: products,
              theme: theme,
              onProductTap: _openProduct,
            ),
          ),
        ),
      ];
    }

    // ── Modo "Todos" + grid/list: agrupado por categoría ─────────────
    if (_isAllMode) {
      final groups = _groupedProducts;
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: groups
                  .map((g) => _buildGroup(g.cat, g.items, theme))
                  .toList(),
            ),
          ),
        ),
      ];
    }

    // ── Categoría individual grid ─────────────────────────────────────
    if (_activeView == _View.grid) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridColumns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 280,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _tarjeta(products[i], theme),
              childCount: products.length,
            ),
          ),
        ),
      ];
    }

    // ── Categoría individual lista ────────────────────────────────────
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _listColumns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 0,
            mainAxisExtent: 140,
          ),
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _fila(products[i], theme),
            ),
            childCount: products.length,
          ),
        ),
      ),
    ];
  }

  // Grupo de categoría para modo "Todos"
  // Tarjeta y fila de un producto. Editando el menú se envuelven con el "⋯" de edición (ProductoEditable).
  Widget _tarjeta(MenuProduct p, MenuTheme theme) => ProductoEditable(
        producto: p,
        child: ProductCard(product: p, theme: theme, onTap: () => _openProduct(p)),
      );

  Widget _fila(MenuProduct p, MenuTheme theme) => ProductoEditable(
        producto: p,
        child: ProductListItem(product: p, theme: theme, onTap: () => _openProduct(p)),
      );

  Widget _buildGroup(
    MenuCategory cat,
    List<MenuProduct> items,
    MenuTheme theme,
  ) {
    final edicion = EdicionMenu.of(context);
    final vistaGrupo = cat.tipoContenido == 'sin_imagenes'
        ? _View.list
        : _activeView;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-header de categoría
          Row(
            children: [
              Text(
                cat.isVisible ? cat.name : '${cat.name} (oculta)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: cat.isVisible ? theme.text : theme.textMuted,
                ),
              ),
              // editando: agregar un producto directo a esta categoría
              if (edicion != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => edicion.abrir('producto-nuevo', cat.id),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(99)),
                    child: const Text('+ Producto',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(child: Divider(color: theme.border, height: 1)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.surfaceAlt,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Grid o lista según la vista del grupo. Una categoría sin
          // imágenes siempre usa lista, igual que React.
          if (vistaGrupo == _View.grid)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridColumns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 280,
              ),
              itemCount: items.length,
              itemBuilder: (ctx, i) => _tarjeta(items[i], theme),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _listColumns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 0,
                mainAxisExtent: 140,
              ),
              itemCount: items.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _fila(items[i], theme),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedRow extends StatelessWidget {
  const _FeaturedRow({
    required this.products,
    required this.theme,
    required this.onTap,
  });

  final List<MenuProduct> products;
  final MenuTheme theme;
  final ValueChanged<MenuProduct> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 15, color: theme.primary),
                const SizedBox(width: 6),
                Text(
                  'Destacados',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: theme.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 178,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final product = products[index];
                return GestureDetector(
                  onTap: () => onTap(product),
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(theme.cardRadius),
                      border: Border.all(color: theme.border),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 100,
                          width: double.infinity,
                          child:
                              product.imageUrl != null &&
                                  product.imageUrl!.isNotEmpty
                              ? Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      Container(color: theme.surfaceAlt),
                                )
                              : Container(
                                  color: theme.surfaceAlt,
                                  child: Icon(
                                    Icons.restaurant_outlined,
                                    color: theme.textMuted,
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: theme.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.hasPromo
                                    ? '\$${product.promoPrice!.toStringAsFixed(0)}'
                                    : '\$${product.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: product.hasPromo
                                      ? const Color(0xFF22C55E)
                                      : theme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Navbar Row (equivale al <header> de Navbar.jsx) ──────────────────────────
class _NavbarRow extends StatelessWidget {
  const _NavbarRow({
    required this.info,
    required this.theme,
    required this.searchOpen,
    required this.searchCtrl,
    required this.onToggle,
    required this.onSearchChange,
    this.onQr,
  });
  final MenuInfo info;
  final MenuTheme theme;
  final bool searchOpen;
  final TextEditingController searchCtrl;
  final VoidCallback onToggle;
  final ValueChanged<String> onSearchChange;
  final VoidCallback? onQr;

  @override
  Widget build(BuildContext context) {
    final t = theme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Back button si hay ruta anterior
          if (context.canPop()) ...[
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.navBg,
                  borderRadius: BorderRadius.circular(t.badgeRadius),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: t.navText,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Lado izquierdo: logo + nombre / campo de búsqueda
          Expanded(
            child: searchOpen
                ? _SearchField(
                    ctrl: searchCtrl,
                    theme: t,
                    onChanged: onSearchChange,
                  )
                : _BusinessInfo(info: info, theme: t),
          ),
          const SizedBox(width: 8),

          // Botón QR
          if (onQr != null)
            _NavBtn(icon: Icons.qr_code, theme: t, onTap: onQr!),

          // Toggle búsqueda
          _NavBtn(
            icon: searchOpen ? Icons.close : Icons.search,
            theme: t,
            active: searchOpen,
            onTap: onToggle,
          ),
        ],
      ),
    );
  }
}

class _BusinessInfo extends StatelessWidget {
  const _BusinessInfo({required this.info, required this.theme});
  final MenuInfo info;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(t.badgeRadius),
          child: info.logoUrl != null && info.logoUrl!.isNotEmpty
              ? Image.network(
                  info.logoUrl!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, st) =>
                      _InitialsAvatar(name: info.name, theme: t),
                )
              : _InitialsAvatar(name: info.name, theme: t),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: t.navText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (info.hasSchedule)
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 10,
                      color: t.navText.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        info.schedule!,
                        style: TextStyle(
                          fontSize: 10,
                          color: t.navText.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, required this.theme});
  final String name;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    color: theme.primary,
    alignment: Alignment.center,
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 16,
      ),
    ),
  );
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.ctrl,
    required this.theme,
    required this.onChanged,
  });
  final TextEditingController ctrl;
  final MenuTheme theme;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(t.buttonRadius),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.search, size: 14, color: t.textMuted),
          ),
          Expanded(
            child: TextField(
              controller: widget.ctrl,
              autofocus: true,
              onChanged: widget.onChanged,
              style: TextStyle(fontSize: 13, color: t.text),
              decoration: InputDecoration(
                hintText: 'Buscar en el menú...',
                hintStyle: TextStyle(fontSize: 13, color: t.textMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.ctrl.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                widget.ctrl.clear();
                widget.onChanged('');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.close, size: 14, color: t.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.theme,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final MenuTheme theme;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: active ? theme.primary : theme.navText.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Icon(icon, size: 17, color: active ? Colors.white : theme.navText),
    ),
  );
}

// ── Toggle de vistas ─────────────────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.view,
    required this.theme,
    required this.onChanged,
    this.onlyList = false,
  });
  final _View view;
  final MenuTheme theme;
  final ValueChanged<_View> onChanged;
  final bool onlyList;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: onlyList
            ? [
                _Btn(
                  icon: Icons.list_outlined,
                  active: true,
                  theme: theme,
                  onTap: () => onChanged(_View.list),
                ),
              ]
            : [
                _Btn(
                  icon: Icons.grid_view_outlined,
                  active: view == _View.grid,
                  theme: theme,
                  onTap: () => onChanged(_View.grid),
                ),
                _Btn(
                  icon: Icons.list_outlined,
                  active: view == _View.list,
                  theme: theme,
                  onTap: () => onChanged(_View.list),
                ),
                _Btn(
                  icon: Icons.view_carousel_outlined,
                  active: view == _View.carousel,
                  theme: theme,
                  onTap: () => onChanged(_View.carousel),
                ),
              ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.icon,
    required this.active,
    required this.theme,
    required this.onTap,
  });
  final IconData icon;
  final bool active;
  final MenuTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: active ? theme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 14,
        color: active ? Colors.white : theme.textMuted,
      ),
    ),
  );
}

// ── Delegate para CategoryTabs sticky ────────────────────────────────────────
class _TabDelegate extends SliverPersistentHeaderDelegate {
  const _TabDelegate({required this.child});
  final Widget child;

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(_TabDelegate old) => old.child != child;
}
