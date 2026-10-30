import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../app.dart' show routeObserver;
import '../../../components/layout/sidebar.dart';
import '../../../components/ui/auth_required_modal.dart';
import '../../../context/auth_context.dart';
import '../../../context/likes_context.dart';
import '../../../context/notificacion_context.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/splash_screen.dart';
import '../components/filtros.dart';
import '../components/infinite_explorer.dart';
import '../components/menu_card.dart';
import '../components/productos_mosaico.dart';
import '../components/skeleton_menu_card.dart';
import '../hooks/use_explore.dart';
import '../models/explore_models.dart';

// Equivalente a src/modules/explore/pages/ExplorePage.jsx en React
// Página principal pública — no requiere autenticación

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) => const _ExploreView();
}

class _ExploreView extends StatefulWidget {
  const _ExploreView();

  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView> with RouteAware {
  bool _splashVisible = false;
  bool _initialized = false;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthContext>().addListener(_onAuthChanged);
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = context.read<AuthContext>();
    context.read<ExploreController>().onAuthChanged(
      isLoggedIn: auth.isLoggedIn,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);

    if (!_initialized) {
      _initialized = true;
      final auth = context.read<AuthContext>();
      final ctrl = context.read<ExploreController>();
      ctrl.init(isLoggedIn: auth.isLoggedIn);
      _splashVisible = ctrl.initialLoading;
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    try {
      context.read<AuthContext>().removeListener(_onAuthChanged);
    } catch (_) {}
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.extentAfter < 500) {
      context.read<ExploreController>().loadMoreActive();
    }
  }

  @override
  void didPopNext() => context.read<ExploreController>().silentRefresh();

  String _returnTo() => GoRouterState.of(context).uri.toString();

  void _requireLogin() {
    showAuthRequiredDialog(context, returnTo: _returnTo());
  }

  void _abrirMenu(TarjetaMenu menu) {
    if (menu.slug.isEmpty) return;
    context.push('/menu/${menu.slug}');
  }

  void _abrirProducto(TarjetaProducto producto) {
    if (producto.menuSlug.isEmpty) return;
    context.push(
      '/menu/${producto.menuSlug}?producto=${Uri.encodeComponent(producto.codigo)}',
    );
  }

  Future<void> _toggleMenu(TarjetaMenu menu, LikesContext likes) async {
    if (!likes.conSesion) {
      _requireLogin();
      return;
    }
    await likes.toggleMenu(menu.slug, menu.codigo);
  }

  Future<void> _toggleProducto(
    TarjetaProducto producto,
    LikesContext likes,
  ) async {
    if (!likes.conSesion) {
      _requireLogin();
      return;
    }
    await likes.toggleProducto(producto.menuSlug, producto.codigo);
  }

  void _abrirQrScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QrScannerSheet(
        onSlugDetected: (slug) {
          Navigator.of(context).pop();
          context.push('/menu/$slug');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ExploreController>();
    final auth = context.watch<AuthContext>();
    final notifCtx = context.watch<NotificacionContext>();

    return Stack(
      children: [
        _buildContent(context, ctrl, auth, notifCtx),
        if (_splashVisible)
          SplashOverlay(
            loading: ctrl.initialLoading,
            noInternet: ctrl.noInternet && !ctrl.hasAnyData,
            onDismissed: () => setState(() => _splashVisible = false),
            onRetry: () => ctrl.refresh(),
          ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    ExploreController ctrl,
    AuthContext auth,
    NotificacionContext notifCtx,
  ) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) async {
        final salir = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              '¿Salir de Zammpy?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            content: const Text(
              '¿Deseas cerrar la aplicación?',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Salir'),
              ),
            ],
          ),
        );
        if (salir == true) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.kBgPage,
        drawer: const AppSidebar(),
        appBar: _buildAppBar(context, auth, notifCtx),
        body: RefreshIndicator(
          color: AppColors.kBlue,
          onRefresh: ctrl.refresh,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _DemoBanner(onTap: () => context.push('/preview/demo')),
                    const SizedBox(height: 20),
                    const _DiscoverHeader(),
                    const SizedBox(height: 14),
                    _ExploreTabs(vista: ctrl.vista, onChanged: ctrl.setVista),
                    const SizedBox(height: 16),
                    _ExploreBody(
                      ctrl: ctrl,
                      likes: context.watch<LikesContext>(),
                      onOpenMenu: _abrirMenu,
                      onOpenProducto: _abrirProducto,
                      onToggleMenu: (menu) =>
                          _toggleMenu(menu, context.read<LikesContext>()),
                      onToggleProducto: (producto) => _toggleProducto(
                        producto,
                        context.read<LikesContext>(),
                      ),
                      onRequireLogin: _requireLogin,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthContext auth,
    NotificacionContext notifCtx,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.kCardBorder)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(
                      Icons.menu,
                      size: 22,
                      color: AppColors.kTextPrimary,
                    ),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                Expanded(
                  child: SvgPicture.asset(
                    'assets/logos/imagotipo-indigo-zammpy.svg',
                    height: 26,
                    alignment: Alignment.centerLeft,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF4A37F2),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                if (auth.isLoggedIn) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.qr_code_scanner_outlined,
                      size: 20,
                      color: AppColors.kTextSecondary,
                    ),
                    onPressed: _abrirQrScanner,
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: AppColors.kTextSecondary,
                        ),
                        onPressed: () {
                          notifCtx.resetUnread();
                          context.push('/notifications');
                        },
                      ),
                      if (notifCtx.unread > 0)
                        const Positioned(
                          top: 10,
                          right: 10,
                          child: _UnreadDot(),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => context.push('/perfil'),
                      child: _UserAvatar(
                        name: auth.displayName,
                        avatarUrl: auth.avatarUrl,
                      ),
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TextButton(
                      onPressed: () => context.push('/login'),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.kBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreBody extends StatelessWidget {
  const _ExploreBody({
    required this.ctrl,
    required this.likes,
    required this.onOpenMenu,
    required this.onOpenProducto,
    required this.onToggleMenu,
    required this.onToggleProducto,
    required this.onRequireLogin,
  });

  final ExploreController ctrl;
  final LikesContext likes;
  final void Function(TarjetaMenu) onOpenMenu;
  final void Function(TarjetaProducto) onOpenProducto;
  final void Function(TarjetaMenu) onToggleMenu;
  final void Function(TarjetaProducto) onToggleProducto;
  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    final menusTab = ctrl.vista == 'menus';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchBar(
          value: menusTab ? ctrl.search : ctrl.busquedaPlatos,
          hintText: menusTab
              ? 'Buscar restaurante por nombre...'
              : 'Buscar plato por nombre...',
          onChanged: menusTab ? ctrl.setSearch : ctrl.setBusquedaPlatos,
          onClear: menusTab
              ? ctrl.clearSearch
              : () => ctrl.setBusquedaPlatos(''),
        ),
        const SizedBox(height: 12),
        if (ctrl.filtrosError != null)
          _FilterError(onRetry: ctrl.cargarFiltros)
        else
          Filtros(
            filtros: ctrl.filtros,
            municipio: menusTab ? ctrl.municipioMenus : ctrl.municipioPlatos,
            categoria: menusTab ? ctrl.categoriaMenus : ctrl.categoriaPlatos,
            onMunicipio: menusTab
                ? ctrl.cambiarMunicipioMenus
                : ctrl.cambiarMunicipioPlatos,
            onCategoria: menusTab
                ? ctrl.cambiarCategoriaMenus
                : ctrl.cambiarCategoriaPlatos,
          ),
        const SizedBox(height: 14),
        if (ctrl.noInternet && ctrl.hasAnyData) ...[
          const _NoInternetBanner(),
          const SizedBox(height: 12),
        ],
        if (menusTab) ...[
          if (ctrl.showingSearch)
            _SearchResults(
              ctrl: ctrl,
              likes: likes,
              onOpenMenu: onOpenMenu,
              onToggleMenu: onToggleMenu,
              onRequireLogin: onRequireLogin,
            )
          else
            InfiniteExplorer(
              items: ctrl.menus,
              loading: ctrl.menuLoading,
              hasMore: ctrl.menuHasMore,
              error: ctrl.menusError,
              onRetry: () => ctrl.loadMenus(reset: true),
              likedIds: likes.menuIds,
              conSesion: likes.conSesion,
              onTap: onOpenMenu,
              onToggleLike: onToggleMenu,
              onRequireLogin: onRequireLogin,
            ),
        ] else
          ProductosMosaico(
            items: ctrl.productos,
            loading: ctrl.productoLoading,
            hasMore: ctrl.productoHasMore,
            error: ctrl.productosError,
            q: ctrl.qPlatos,
            onRetry: () => ctrl.loadProductos(reset: true),
            likedIds: likes.productIds,
            conSesion: likes.conSesion,
            onTap: onOpenProducto,
            onToggleLike: onToggleProducto,
            onRequireLogin: onRequireLogin,
          ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.ctrl,
    required this.likes,
    required this.onOpenMenu,
    required this.onToggleMenu,
    required this.onRequireLogin,
  });

  final ExploreController ctrl;
  final LikesContext likes;
  final void Function(TarjetaMenu) onOpenMenu;
  final void Function(TarjetaMenu) onToggleMenu;
  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    if (ctrl.searchLoading) {
      return const Column(
        children: [
          SkeletonMenuCard(),
          SizedBox(height: 10),
          SkeletonMenuCard(),
          SizedBox(height: 10),
          SkeletonMenuCard(),
        ],
      );
    }

    final results = ctrl.searchResults;
    if (results == null) return const SizedBox.shrink();

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Sin resultados para "${ctrl.search}"',
            style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted),
          ),
        ),
      );
    }

    return GridView.builder(
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
      itemCount: results.length,
      itemBuilder: (context, index) {
        final menu = results[index];
        return MenuCard(
          menu: menu,
          liked: likes.menuLiked(menu.codigo),
          conSesion: likes.conSesion,
          onTap: () => onOpenMenu(menu),
          onToggleLike: () => onToggleMenu(menu),
          onRequireLogin: onRequireLogin,
        );
      },
    );
  }
}

class _ExploreTabs extends StatelessWidget {
  const _ExploreTabs({required this.vista, required this.onChanged});

  final String vista;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Menús',
              icon: Icons.storefront_outlined,
              active: vista == 'menus',
              onTap: () => onChanged('menus'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TabButton(
              label: 'Platos',
              icon: Icons.restaurant_menu,
              active: vista == 'platos',
              onTap: () => onChanged('platos'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.kBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.kBlue.withValues(alpha: 0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: active ? Colors.white : AppColors.kTextSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : AppColors.kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterError extends StatelessWidget {
  const _FilterError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'No se pudieron cargar los filtros.',
              style: TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

// ── Banner Demo ───────────────────────────────────────────────────────────────
class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 176,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1200&q=75',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    Container(color: AppColors.kSkeleton),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xB3000000),
                      Color(0x66000000),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.4, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.kBlueLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 10,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Menu de ejemplo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                bottom: 16,
                left: 16,
                right: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Burger & More',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sabor que enamora, calidad que conquista',
                      style: TextStyle(color: Color(0xAAFFFFFF), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descubrir',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.kTextPrimary,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Menús y platos cerca de ti',
          style: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
        ),
      ],
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.value,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final String value;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.value;
  }

  @override
  void didUpdateWidget(_SearchBar old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search, size: 16, color: AppColors.kTextMuted),
          ),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: widget.onChanged,
              maxLength: 100,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.kTextPrimary,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.kTextMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.value.isNotEmpty)
            GestureDetector(
              onTap: () {
                _ctrl.clear();
                widget.onClear();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.close, size: 14, color: AppColors.kTextMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoInternetBanner extends StatelessWidget {
  const _NoInternetBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 14, color: Color(0xFFC2410C)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin conexión · Mostrando datos guardados',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9A3412),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: const BoxDecoration(
      color: AppColors.kBlue,
      shape: BoxShape.circle,
    ),
  );
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name, this.avatarUrl});
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 15,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: Color(0xFFE0E7FF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: name.isNotEmpty
            ? Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kBlue,
                ),
              )
            : const Icon(
                Icons.person_outline,
                size: 15,
                color: AppColors.kBlue,
              ),
      ),
    );
  }
}

// ── Escáner QR ────────────────────────────────────────────────────────────────
class _QrScannerSheet extends StatefulWidget {
  const _QrScannerSheet({required this.onSlugDetected});

  final void Function(String slug) onSlugDetected;

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  late final MobileScannerController _ctrl;
  bool _handled = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _ctrl = MobileScannerController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue ?? '';
    final slug = _zammpySlug(raw);
    if (slug != null) {
      _handled = true;
      widget.onSlugDetected(slug);
    } else if (raw.isNotEmpty) {
      _handled = true;
      setState(() => _errorMsg = 'El QR no pertenece a un menú de Zammpy');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _errorMsg = null;
            _handled = false;
          });
        }
      });
    }
  }

  String? _zammpySlug(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      const valid = {'zammpy.com', 'www.zammpy.com', 'app.zammpy.com'};
      if (!valid.contains(host)) return null;
      final segs = uri.pathSegments;
      if (segs.length >= 2 && segs[0] == 'menu' && segs[1].isNotEmpty) {
        return segs[1];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.78;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: h,
        child: Stack(
          children: [
            MobileScanner(controller: _ctrl, onDetect: _onDetect),
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _errorMsg != null
                        ? const Color(0xFFEF4444)
                        : AppColors.kBlue,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            if (_errorMsg != null)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 240),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _errorMsg!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Escanear menú Zammpy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black45,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _errorMsg == null
                      ? 'Apunta al código QR de un menú Zammpy'
                      : 'Intenta con otro código QR',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
