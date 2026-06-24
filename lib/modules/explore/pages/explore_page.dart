import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../components/layout/sidebar.dart';
import '../../../context/auth_context.dart';
import '../../../context/notificacion_context.dart';
import '../../../shared/app_colors.dart';
import '../../menu/public/models/public_menu_model.dart';
import '../hooks/use_explore.dart';
import '../components/menu_card.dart';
import '../components/skeleton_card.dart';
import '../components/section.dart';
import '../components/location_banner.dart';
import '../components/infinite_explorer.dart';
import '../../../shared/splash_screen.dart';
import '../../../app.dart' show routeObserver;

// Equivalente a src/modules/explore/pages/ExplorePage.jsx en React
// Página principal pública — no requiere autenticación

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final auth = ctx.read<AuthContext>();
        return ExploreController()..init(isLoggedIn: auth.isLoggedIn);
      },
      child: const _ExploreView(),
    );
  }
}

class _ExploreView extends StatefulWidget {
  const _ExploreView();

  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView> with RouteAware {
  bool _splashVisible = false;
  bool _initialized   = false;

  @override
  void initState() {
    super.initState();
    // Listener de auth para recargar likes al iniciar/cerrar sesión
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthContext>().addListener(_onAuthChanged);
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = context.read<AuthContext>();
    final ctrl = context.read<ExploreController>();
    if (auth.isLoggedIn) {
      ctrl.reloadLikes();
    } else {
      ctrl.clearLikes();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Suscribir al RouteObserver para detectar cuando el usuario vuelve al explorador
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);

    if (!_initialized) {
      _initialized   = true;
      final ctrl     = context.read<ExploreController>();
      _splashVisible = ctrl.feedLoading;
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    try { context.read<AuthContext>().removeListener(_onAuthChanged); } catch (_) {}
    super.dispose();
  }

  // Volvió al explorador desde otra pantalla → refetch en background (sin spinner)
  @override
  void didPopNext() {
    final ctrl = context.read<ExploreController>();
    ctrl.loadFeed(ctrl.ciudad);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl     = context.watch<ExploreController>();
    final auth     = context.watch<AuthContext>();
    final notifCtx = context.watch<NotificacionContext>();

    return Stack(
      children: [
        _buildContent(context, ctrl, auth, notifCtx),
        if (_splashVisible)
          SplashOverlay(
            loading:    ctrl.feedLoading,
            // Bloquear entrada si no hay internet Y no hay datos reales que mostrar
            noInternet: ctrl.noInternet && !ctrl.hasFeedData,
            onDismissed: () => setState(() => _splashVisible = false),
            onRetry:     () => ctrl.loadFeed(ctrl.ciudad),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ExploreController ctrl,
      AuthContext auth, NotificacionContext notifCtx) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) async {
        final salir = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Salir de Zammpy?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            content: const Text('¿Deseas cerrar la aplicación?',
                style: TextStyle(fontSize: 14)),
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
        onRefresh: () => ctrl.loadFeed(ctrl.ciudad),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              // p-4 md:p-6 max-w-3xl mx-auto — en móvil es p-4
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Banner demo ─────────────────────────────────────────
                  _DemoBanner(
                    onTap: () => context.push('/preview/demo'),
                  ),
                  const SizedBox(height: 20),

                  // ── Encabezado "Descubrir" ───────────────────────────────
                  const _DiscoverHeader(),
                  const SizedBox(height: 16),

                  // ── Banner de ubicación ──────────────────────────────────
                  if (ctrl.locBanner) ...[
                    LocationBanner(
                      onGranted: (lat, lon) => ctrl.handleLocationGranted(lat, lon),
                      onDismiss: ctrl.handleDismissLocation,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Barra de búsqueda ────────────────────────────────────
                  _SearchBar(
                    value:     ctrl.search,
                    onChanged: ctrl.setSearch,
                    onClear:   ctrl.clearSearch,
                  ),
                  const SizedBox(height: 16),

                  // ── Banner sin internet (solo cuando hay datos en pantalla) ─
                  if (ctrl.noInternet && ctrl.hasFeedData) ...[
                    const _NoInternetBanner(),
                    const SizedBox(height: 12),
                  ],

                  // ── Resultados de búsqueda ───────────────────────────────
                  if (ctrl.showingSearch)
                    _SearchResults(ctrl: ctrl, auth: auth)
                  else
                    _Feed(
                      key:  ValueKey(ctrl.offlineRecoveredVersion),
                      ctrl: ctrl,
                      auth: auth,
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    ),   // cierre Scaffold
    );   // cierre PopScope
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AuthContext auth, NotificacionContext notifCtx) {
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
                // Hamburger — abre el Sidebar (Drawer)
                Builder(builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, size: 22, color: AppColors.kTextPrimary),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                )),
                // Logo alineado a la izquierda — imagotipo-indigo-zammpy.svg
                Expanded(
                  child: SvgPicture.asset(
                    'assets/logos/imagotipo-indigo-zammpy.svg',
                    height: 26,
                    alignment: Alignment.centerLeft,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF4A37F2), BlendMode.srcIn),
                  ),
                ),
                if (auth.isLoggedIn) ...[
                  // Notificaciones con badge
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            size: 20, color: AppColors.kTextSecondary),
                        onPressed: () {
                          notifCtx.resetUnread();
                          context.push('/notifications');
                        },
                      ),
                      if (notifCtx.unread > 0)
                        const Positioned(
                          top: 10, right: 10,
                          child: _UnreadDot(),
                        ),
                    ],
                  ),
                  // Avatar del usuario
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => context.push('/perfil'),
                      child: _UserAvatar(name: auth.displayName, avatarUrl: auth.avatarUrl),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Iniciar sesión',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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

// ── Banner Demo ───────────────────────────────────────────────────────────────
class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // rounded-3xl overflow-hidden h-44 — igual que React
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 176, // h-44
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1200&q=75',
                fit: BoxFit.cover,
                errorBuilder: (_, e, st) => Container(color: AppColors.kSkeleton),
              ),
              // Gradiente from-black/70 via-black/40 to-transparent
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xB3000000), Color(0x66000000), Colors.transparent],
                    stops: [0.0, 0.4, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              // Badge "Menu de ejemplo" top-left
              Positioned(
                top: 16, left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.kBlueLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: 10, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Menu de ejemplo',
                          style: TextStyle(color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              // Texto bottom-left
              const Positioned(
                bottom: 16, left: 16, right: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Burger & More',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                            fontSize: 20,
                            shadows: [Shadow(blurRadius: 6, color: Colors.black45)]),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2),
                    Text('Sabor que enamora, calidad que conquista',
                        style: TextStyle(color: Color(0xAAFFFFFF), fontSize: 11)),
                  ],
                ),
              ),
              // Flecha bottom-right
              Positioned(
                bottom: 16, right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                  ),
                  child: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Encabezado Descubrir ──────────────────────────────────────────────────────
class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Descubrir',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                color: AppColors.kTextPrimary)),
        SizedBox(height: 2),
        Text('Menús publicados por restaurantes',
            style: TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
      ],
    );
  }
}

// ── Barra de búsqueda ─────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  final String          value;
  final ValueChanged<String> onChanged;
  final VoidCallback    onClear;

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
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // w-full pl-9 pr-9 py-2.5 rounded-xl border border-slate-200 — igual que React
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
              style: const TextStyle(fontSize: 13, color: AppColors.kTextPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar restaurante o slogan...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
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

// ── Resultados de búsqueda ────────────────────────────────────────────────────
class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.ctrl, required this.auth});
  final ExploreController ctrl;
  final AuthContext        auth;

  @override
  Widget build(BuildContext context) {
    if (ctrl.searchLoading) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12,
          mainAxisSpacing: 12, childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (_, i) => const SkeletonCard(),
      );
    }

    final results = ctrl.searchResults;

    if (results == null || results.isEmpty) {
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12,
        mainAxisSpacing: 12, childAspectRatio: 0.75,
      ),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final item = results[i];
        return MenuCard(
          menu:  item,
          liked: ctrl.likedIds.contains(item.menId),
          onTap: () => context.push('/menu/${item.slug}'),
          onToggleLike: () => ctrl.toggleLike(item, auth.isLoggedIn),
        );
      },
    );
  }
}

// ── Feed principal ────────────────────────────────────────────────────────────
class _Feed extends StatelessWidget {
  const _Feed({super.key, required this.ctrl, required this.auth});
  final ExploreController ctrl;
  final AuthContext        auth;

  @override
  Widget build(BuildContext context) {
    if (ctrl.feedLoading) {
      return Section(
        icon: Icons.auto_awesome,
        title: 'Explorador',
        loading: true,
        likedIds: const {},
      );
    }

    final d = ctrl.deduped;

    final hasContent = (d.dedupedFeed.nearby.isNotEmpty) ||
        (d.dedupedFeed.trending.isNotEmpty) ||
        (d.dedupedFeed.nuevo.isNotEmpty);

    if (!hasContent) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: Column(children: [
            Text('Aún no hay menús publicados',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.kTextPrimary)),
            SizedBox(height: 4),
            Text('Sé el primero en publicar el tuyo.',
                style: TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
          ]),
        ),
      );
    }

    void openMenu(MenuFeedItem item) =>
        context.push('/menu/${item.slug}');

    void toggleLike(MenuFeedItem item) =>
        ctrl.toggleLike(item, auth.isLoggedIn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (d.dedupedFeed.nearby.isNotEmpty) ...[
          Section(
            icon:         Icons.location_on_outlined,
            title:        ctrl.ciudad != null
                ? 'Cerca de ti · ${ctrl.ciudad}'
                : 'Cerca de ti',
            items:        d.dedupedFeed.nearby,
            likedIds:     ctrl.likedIds,
            onCardTap:    openMenu,
            onToggleLike: toggleLike,
          ),
          const SizedBox(height: 24),
        ],
        if (d.dedupedFeed.trending.isNotEmpty) ...[
          Section(
            icon:         Icons.local_fire_department_outlined,
            title:        'Tendencias',
            items:        d.dedupedFeed.trending,
            likedIds:     ctrl.likedIds,
            onCardTap:    openMenu,
            onToggleLike: toggleLike,
          ),
          const SizedBox(height: 24),
        ],
        if (d.dedupedFeed.nuevo.isNotEmpty) ...[
          Section(
            icon:         Icons.auto_awesome,
            title:        'Nuevos',
            items:        d.dedupedFeed.nuevo,
            likedIds:     ctrl.likedIds,
            onCardTap:    openMenu,
            onToggleLike: toggleLike,
          ),
          const SizedBox(height: 24),
        ],

        // Explorador con scroll infinito
        InfiniteExplorer(
          key:          ValueKey('explorer-v${ctrl.feedVersion}'),
          ciudad:       ctrl.ciudad,
          excludeIds:   d.excludeIds,
          likedIds:     ctrl.likedIds,
          onCardTap:    openMenu,
          onToggleLike: toggleLike,
        ),
      ],
    );
  }
}

// ── Banner sin conexión (cuando ya hay datos en pantalla) ─────────────────────
class _NoInternetBanner extends StatelessWidget {
  const _NoInternetBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        const Color(0xFFFFF7ED),
        border:       Border.all(color: const Color(0xFFFED7AA)),
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
                fontSize:   12,
                fontWeight: FontWeight.w500,
                color:      Color(0xFF9A3412),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares del AppBar ─────────────────────────────────────────────
class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) => Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(
            color: AppColors.kBlue, shape: BoxShape.circle),
      );
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name, this.avatarUrl});
  final String  name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(radius: 15, backgroundImage: NetworkImage(avatarUrl!));
    }
    return Container(
      width: 30, height: 30,
      decoration: const BoxDecoration(
          color: Color(0xFFE0E7FF), shape: BoxShape.circle),
      child: Center(
        child: name.isNotEmpty
            ? Text(name[0].toUpperCase(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.kBlue))
            : const Icon(Icons.person_outline, size: 15, color: AppColors.kBlue),
      ),
    );
  }
}
