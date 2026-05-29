import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_cache.dart';
import '../menu_publico/public_menu_screen.dart';
import '../../core/push_service.dart';
import '../../shared/app_colors.dart';
import '../../shared/widgets/app_drawer.dart';
import '../auth/auth_service.dart';
import '../notifications/notification_service.dart';
import '../notifications/notifications_screen.dart';
import 'explore_service.dart';
import 'models/menu_feed_item.dart';
import 'widgets/explore_section_widget.dart';
import 'widgets/menu_card_widget.dart';
import 'widgets/skeleton_card_widget.dart';

/// Pantalla principal post-login.
/// Equivalente a ExplorePage.jsx (vista móvil) + Header.jsx + BottomNav.jsx.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // ── Búsqueda ───────────────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  String _search = '';
  Timer? _searchTimer;
  List<MenuFeedItem>? _searchResults;
  bool _searchLoading = false;

  // ── Feed ───────────────────────────────────────────────────────────────────
  ExploreFeed? _feed;
  bool _feedLoading = true;

  // ── Infinite scroll ────────────────────────────────────────────────────────
  final List<MenuFeedItem> _infiniteItems = [];
  int _infiniteOffset = 0;
  bool _infiniteHasMore = true;
  bool _infiniteLoading = false;
  final _scrollCtrl = ScrollController();

  // ── Liked ──────────────────────────────────────────────────────────────────
  Set<int> _likedIds = {};

  // ── Usuario ────────────────────────────────────────────────────────────────
  String _userName = '';
  int _unreadCount = 0;

  // ── Scaffold key (para abrir el Drawer desde el AppBar) ───────────────────
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── WebSocket ──────────────────────────────────────────────────────────────
  StreamSubscription<void>? _wsSub;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // Mostrar cache al instante antes del fetch
    final cachedFeed = AppCache.get<ExploreFeed>('explore_feed');
    final cachedInfinite = AppCache.get<List<MenuFeedItem>>('explore_infinite');
    if (cachedFeed != null) {
      _feed = cachedFeed;
      _feedLoading = false;
    }
    if (cachedInfinite != null) {
      _infiniteItems.addAll(cachedInfinite);
      _infiniteOffset = cachedInfinite.length;
    }
    _loadInitialData();
    PushService.connect();
    _wsSub = PushService.onNewNotification.listen((_) {
      if (mounted) setState(() => _unreadCount++);
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    // Desconectar WebSocket al salir de ExploreScreen para que el próximo
    // usuario que inicie sesión se conecte con sus propias credenciales.
    PushService.disconnect();
    _searchCtrl.dispose();
    _searchTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Refresh (pull-to-refresh) ──────────────────────────────────────────────
  Future<void> _refresh() async {
    setState(() {
      _feedLoading = true;
      _infiniteItems.clear();
      _infiniteOffset = 0;
      _infiniteHasMore = true;
    });
    await _loadInitialData();
  }

  // ── Carga inicial ──────────────────────────────────────────────────────────
  Future<void> _loadInitialData() async {
    // Nombre del usuario para el avatar del header
    AuthService.getAuthData().then((data) {
      if (data != null && mounted) {
        setState(() => _userName = (data['nombre'] as String? ?? '').trim());
      }
    });

    // Encantados del usuario (auth)
    ExploreService.misEncantados().then((ids) {
      if (mounted) setState(() => _likedIds = ids);
    });

    // Conteo de notificaciones sin leer (para badge en bell y BottomNav)
    NotificationService.getSinLeer().then((count) {
      if (mounted) setState(() => _unreadCount = count);
    });

    // Feed principal
    final feed = await ExploreService.getFeed();
    if (!mounted) return;

    final seen = <int>{};
    List<MenuFeedItem> filterSeen(List<MenuFeedItem> list) =>
        list.where((m) => m.menId != 0 && seen.add(m.menId)).toList();

    final dedupedTodos    = filterSeen(feed.todos);
    final dedupedNearby   = filterSeen(feed.nearby);
    final dedupedTrending = filterSeen(feed.trending);
    final dedupedNuevo    = filterSeen(feed.nuevo);

    final newFeed = ExploreFeed(
      todos:    dedupedTodos,
      nearby:   dedupedNearby,
      trending: dedupedTrending,
      nuevo:    dedupedNuevo,
    );

    // Guardar en cache antes de actualizar la UI
    AppCache.set('explore_feed', newFeed);
    AppCache.set('explore_infinite', dedupedTodos);

    setState(() {
      _feed = newFeed;
      _feedLoading = false;
      // Solo reemplazar el infinite si los datos cambiaron
      // (evita parpadeo cuando el cache ya mostraba los mismos items)
      if (_infiniteItems.isEmpty ||
          _infiniteItems.first.menId != dedupedTodos.firstOrNull?.menId) {
        _infiniteItems
          ..clear()
          ..addAll(dedupedTodos);
        _infiniteOffset = dedupedTodos.length;
      }
    });
  }

  // ── Scroll infinito ────────────────────────────────────────────────────────
  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      _loadMoreInfinite();
    }
  }

  Future<void> _loadMoreInfinite() async {
    if (_infiniteLoading || !_infiniteHasMore) return;
    setState(() => _infiniteLoading = true);
    try {
      final data =
          await ExploreService.getMenusPaged(_infiniteOffset);
      if (!mounted) return;
      if (data.isEmpty) {
        setState(() {
          _infiniteHasMore = false;
          _infiniteLoading = false;
        });
      } else {
        // Excluir IDs que ya están en el infinite scroll
        // Y también los que están en las secciones (nearby/trending/nuevo),
        // porque esas ya están deduplicadas y no deben aparecer dos veces.
        final allShown = <int>{
          ..._infiniteItems.map((m) => m.menId),
          ...(_feed?.nearby.map((m) => m.menId) ?? const <int>[]),
          ...(_feed?.trending.map((m) => m.menId) ?? const <int>[]),
          ...(_feed?.nuevo.map((m) => m.menId) ?? const <int>[]),
        };
        setState(() {
          _infiniteItems.addAll(
              data.where((m) => m.menId != 0 && !allShown.contains(m.menId)));
          _infiniteOffset += data.length;
          if (data.length < 24) _infiniteHasMore = false;
          _infiniteLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _infiniteHasMore = false;
          _infiniteLoading = false;
        });
      }
    }
  }

  // ── Búsqueda ───────────────────────────────────────────────────────────────
  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _search = '';
        _searchResults = null;
        _searchLoading = false;
      });
      return;
    }
    setState(() => _search = q);
    _searchTimer = Timer(
      const Duration(milliseconds: 350),
      () => _doSearch(q),
    );
  }

  Future<void> _doSearch(String q) async {
    if (!mounted) return;
    setState(() => _searchLoading = true);
    final results = await ExploreService.buscarMenus(q);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searchLoading = false;
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _onSearchChanged('');
  }

  bool get _showingSearch => _search.trim().isNotEmpty;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.kBgPage,
      drawer: AppDrawer(unreadCount: _unreadCount),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: AppColors.kBlue,
        onRefresh: _refresh,
        child: CustomScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildDemoBanner(),
                const SizedBox(height: 20),
                _buildDiscoverHeader(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 16),
                if (_showingSearch) _buildSearchResults(),
                if (!_showingSearch) _buildFeed(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ── AppBar (Header.jsx) ────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
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
                // Hamburger → abre el Drawer
                IconButton(
                  icon: const Icon(Icons.menu_rounded,
                      size: 20, color: AppColors.kTextSecondary),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                // Título
                const Expanded(
                  child: Text(
                    'Explorar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextPrimary,
                    ),
                  ),
                ),
                // Bell con punto azul (solo si hay sin leer)
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          size: 20, color: AppColors.kTextSecondary),
                      onPressed: _goToNotifications,
                    ),
                    if (_unreadCount > 0)
                      const Positioned(
                        top: 11,
                        right: 11,
                        child: _BlueDot(),
                      ),
                  ],
                ),
                // Avatar usuario
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _UserAvatar(name: _userName),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Demo Banner ────────────────────────────────────────────────────────────
  Widget _buildDemoBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const PublicMenuScreen(isDemo: true))),
      child: Container(
        height: 176,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.kSkeleton,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=75',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: AppColors.kSkeleton),
            ),
            // Degradado izquierda → transparente
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xB3000000),
                    Color(0x55000000),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.45, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            // Badge "Menu de ejemplo" — top-left
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.kBlueLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined,
                        size: 10, color: Colors.white),
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
            // Texto — bottom-left
            const Positioned(
              bottom: 14,
              left: 14,
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
                      shadows: [
                        Shadow(blurRadius: 6, color: Colors.black45),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sabor que enamora, calidad que conquista',
                    style: TextStyle(
                      color: Color(0xAAFFFFFF),
                      fontSize: 11,
                      shadows: [
                        Shadow(blurRadius: 4, color: Colors.black38),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Botón ArrowRight — bottom-right
            Positioned(
              bottom: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30)),
                ),
                child: const Icon(Icons.arrow_forward,
                    size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Encabezado "Descubrir" ─────────────────────────────────────────────────
  Widget _buildDiscoverHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descubrir',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.kTextPrimary,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Menús publicados por restaurantes',
          style: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
        ),
      ],
    );
  }

  // ── Barra de búsqueda ──────────────────────────────────────────────────────
  Widget _buildSearchBar() {
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
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.kTextPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar restaurante o slogan...',
                hintStyle:
                    TextStyle(fontSize: 13, color: AppColors.kTextMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_search.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child:
                    Icon(Icons.close, size: 16, color: AppColors.kTextMuted),
              ),
            ),
        ],
      ),
    );
  }

  // ── Resultados de búsqueda ─────────────────────────────────────────────────
  Widget _buildSearchResults() {
    if (_searchLoading) {
      return _menuList(6, (i) => const SkeletonCardWidget());
    }
    if (_searchResults == null) return const SizedBox.shrink();
    if (_searchResults!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Sin resultados para "$_search"',
            style: const TextStyle(
                fontSize: 13, color: AppColors.kTextMuted),
          ),
        ),
      );
    }
    return _menuList(
      _searchResults!.length,
      (i) => MenuCardWidget(
        menu: _searchResults![i],
        liked: _likedIds.contains(_searchResults![i].menId),
      ),
    );
  }

  // ── Feed principal ─────────────────────────────────────────────────────────
  Widget _buildFeed() {
    if (_feedLoading) {
      return ExploreSectionWidget(
        icon: Icons.auto_awesome,
        title: 'Explorador',
        loading: true,
      );
    }

    final hasContent = _infiniteItems.isNotEmpty ||
        (_feed?.trending.isNotEmpty ?? false) ||
        (_feed?.nuevo.isNotEmpty ?? false);

    if (!hasContent) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: Column(
            children: [
              Text(
                'Aun no hay menús publicados',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Sé el primero en publicar el tuyo.',
                style:
                    TextStyle(fontSize: 13, color: AppColors.kTextMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // InfiniteExplorer
        if (_infiniteItems.isNotEmpty || _infiniteLoading) ...[
          _buildInfiniteSection(),
          const SizedBox(height: 24),
        ],
        // Cerca de ti (si hay ciudad)
        if (_feed?.nearby.isNotEmpty ?? false) ...[
          ExploreSectionWidget(
            icon: Icons.location_on_outlined,
            title: 'Cerca de ti',
            items: _feed!.nearby,
            likedIds: _likedIds,
          ),
          const SizedBox(height: 24),
        ],
        // Tendencias
        if (_feed?.trending.isNotEmpty ?? false) ...[
          ExploreSectionWidget(
            icon: Icons.local_fire_department_outlined,
            title: 'Tendencias',
            items: _feed!.trending,
            likedIds: _likedIds,
          ),
          const SizedBox(height: 24),
        ],
        // Nuevos
        if (_feed?.nuevo.isNotEmpty ?? false) ...[
          ExploreSectionWidget(
            icon: Icons.auto_awesome,
            title: 'Nuevos',
            items: _feed!.nuevo,
            likedIds: _likedIds,
          ),
        ],
      ],
    );
  }

  // ── Sección Infinite Scroll ────────────────────────────────────────────────
  Widget _buildInfiniteSection() {
    final total = _infiniteItems.length + (_infiniteLoading ? 3 : 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, size: 15, color: AppColors.kBlue),
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
        _menuList(total, (i) {
          if (i >= _infiniteItems.length) return const SkeletonCardWidget();
          return MenuCardWidget(
            menu: _infiniteItems[i],
            liked: _likedIds.contains(_infiniteItems[i].menId),
          );
        }),
        if (_infiniteLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.kBlue),
              ),
            ),
          ),
        if (!_infiniteHasMore && _infiniteItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: const [
                Expanded(child: Divider(color: AppColors.kCardBorder)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Has llegado al final',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.kTextMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.kCardBorder)),
              ],
            ),
          ),
      ],
    );
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  Widget _menuList(int count, Widget Function(int) builder) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: builder(i),
        ),
      ),
    );
  }

  Future<void> _goToNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    if (mounted) setState(() => _unreadCount = 0);
  }
}

// ── Pequeños widgets reutilizables del header ──────────────────────────────

class _BlueDot extends StatelessWidget {
  const _BlueDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.kBlue,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: Color(0xFFE0E7FF), // indigo-100
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
            : const Icon(Icons.person_outline,
                size: 15, color: AppColors.kBlue),
      ),
    );
  }
}
