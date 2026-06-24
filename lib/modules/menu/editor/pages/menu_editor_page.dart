import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart' show routeObserver;
import '../../../../context/auth_context.dart';
import '../../../../services/menu_editor_service.dart';
import '../../../../shared/app_colors.dart';
import '../models/editor_menu_model.dart';
import '../tabs/categories_tab.dart';
import '../tabs/colaboradores_tab.dart';
import '../tabs/design_tab.dart';
import '../tabs/grupos_tab.dart';
import '../tabs/products_tab.dart';
import '../tabs/publish_tab.dart';

// Equivalente a src/modules/menu/editor/MenuEditorPage.jsx en React
// Página principal del editor con tabs: Categorías, Productos, Grupos, Diseño,
// Publicar (owner), Colaboradores (owner).

const List<(String id, String label, bool ownerOnly)> _kAllTabs = [
  ('categories',    'Categorías',    false),
  ('products',      'Productos',     false),
  ('grupos',        'Grupos info',   false),
  ('design',        'Diseño',        false),
  ('publish',       'Publicar',      true),
  ('colaboradores', 'Colaboradores', true),
];

class MenuEditorPage extends StatefulWidget {
  const MenuEditorPage({
    super.key,
    required this.menuId,
    this.initialTab,
  });

  final int menuId;
  final String? initialTab;

  @override
  State<MenuEditorPage> createState() => _MenuEditorPageState();
}

class _MenuEditorPageState extends State<MenuEditorPage> with RouteAware {
  EditorMenu? _menu;
  bool _loading    = true;
  bool _saving     = false;
  bool _publishing = false;
  String _tab      = 'categories';
  // Incrementar fuerza el remount del tab activo para mostrar datos frescos
  int _tabKey      = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) _tab = widget.initialTab!;
    _loadMenu();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Llamado al volver de ProductFormPage / MenuInfoPage
  @override
  void didPopNext() => _refreshOnReturn();

  Future<void> _refreshOnReturn() async {
    try {
      final data = await MenuEditorService.getById(widget.menuId);
      if (!mounted) return;
      setState(() { _menu = EditorMenu.fromJson(data); _tabKey++; });
    } catch (_) {}
  }

  Future<void> _loadMenu() async {
    try {
      final data = await MenuEditorService.getById(widget.menuId);
      if (!mounted) return;
      setState(() { _menu = EditorMenu.fromJson(data); _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _handleSave(Map<String, dynamic> patch) async {
    setState(() => _saving = true);
    try {
      final data = await MenuEditorService.updateDraft(widget.menuId, patch);
      if (!mounted) return;
      setState(() => _menu = EditorMenu.fromJson(data));
    } catch (e) {
      if (!mounted) return;
      _showSnack(
          'No se pudo guardar: ${e.toString().replaceFirst('Exception: ', '')}',
          error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handlePublish() async {
    setState(() => _publishing = true);
    try {
      final data = await MenuEditorService.publish(widget.menuId);
      if (!mounted) return;
      setState(() => _menu = EditorMenu.fromJson(data));
      _showSnack('¡Menú publicado exitosamente!');
    } catch (e) {
      if (!mounted) return;
      _showSnack(
          'No se pudo publicar: ${e.toString().replaceFirst('Exception: ', '')}',
          error: true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _handleUnpublish() async {
    try {
      await MenuEditorService.unpublish(widget.menuId);
      if (!mounted) return;
      final data = await MenuEditorService.getById(widget.menuId);
      if (!mounted) return;
      setState(() => _menu = EditorMenu.fromJson(data));
      _showSnack('Menú despublicado.');
    } catch (e) {
      if (!mounted) return;
      _showSnack(
          'Error: ${e.toString().replaceFirst('Exception: ', '')}',
          error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_menu == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo cargar el menú.',
                  style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/menus'),
                child: const Text('Volver a mis menús'),
              ),
            ],
          ),
        ),
      );
    }

    final menu    = _menu!;
    final userId  = context.read<AuthContext>().userId;
    final isOwner = userId != null && menu.ownerId == userId;
    final tabs    = _kAllTabs
        .where((t) => !t.$3 || isOwner)
        .toList();

    // Si el tab activo ya no es visible para este usuario, reset
    final tabIds = tabs.map((t) => t.$1).toList();
    final activeTab = tabIds.contains(_tab) ? _tab : tabIds.first;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────────
            _TopBar(
              menu:    menu,
              isOwner: isOwner,
              menuId:  widget.menuId,
            ),
            // ── Tab navigation ────────────────────────────────────────────────
            _TabNav(
              tabs:        tabs,
              activeTab:   activeTab,
              hasDraft:    menu.hasDraftChanges,
              onSelect:    (id) => setState(() => _tab = id),
            ),
            // ── Content ───────────────────────────────────────────────────────
            Expanded(
              child: _TabContent(
                key:        ValueKey('${activeTab}_$_tabKey'),
                tab:        activeTab,
                menu:       menu,
                isOwner:    isOwner,
                saving:     _saving,
                publishing: _publishing,
                onSave:     _handleSave,
                onPublish:  _handlePublish,
                onUnpublish: _handleUnpublish,
                onGoToCategories: () => setState(() => _tab = 'categories'),
                onTransferido:    () => context.go('/menus'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.menu, required this.isOwner, required this.menuId});
  final EditorMenu menu;
  final bool       isOwner;
  final int        menuId;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          // Back
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/menus'),
            color: const Color(0xFF64748B),
          ),

          // Nombre + slug
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.draft.info.name.isNotEmpty
                      ? menu.draft.info.name
                      : 'Mi menú',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '/menu/${menu.slug}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Status badge
          _StatusBadge(menu: menu, isOwner: isOwner),

          // Stats (owner only)
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.bar_chart, size: 18),
              onPressed: () => context.push('/menus/$menuId/estadisticas'),
              color: const Color(0xFF64748B),
              tooltip: 'Estadísticas',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            ),

          // Info negocio
          GestureDetector(
            onTap: () => context.push('/menus/$menuId/info'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.business_outlined, size: 13, color: Color(0xFF64748B)),
                  SizedBox(width: 4),
                  Text('Info', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ),

          // Preview
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 18),
            onPressed: () => context.push('/preview/$menuId'),
            color: const Color(0xFF64748B),
            tooltip: 'Vista previa',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.menu, required this.isOwner});
  final EditorMenu menu;
  final bool       isOwner;

  @override
  Widget build(BuildContext context) {
    if (!isOwner) {
      return Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Text('Colaborador',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))),
      );
    }

    final published = menu.isPublished;
    final hasDraft  = menu.hasDraftChanges;

    final Color bg;
    final Color text;
    final Color dot;
    final String label;

    if (!published) {
      bg    = const Color(0xFFF1F5F9);
      text  = const Color(0xFF64748B);
      dot   = const Color(0xFF94A3B8);
      label = 'Borrador';
    } else if (hasDraft) {
      bg    = const Color(0xFFFFFBEB);
      text  = const Color(0xFFB45309);
      dot   = const Color(0xFFF59E0B);
      label = 'Cambios';
    } else {
      bg    = const Color(0xFFF0FDF4);
      text  = const Color(0xFF16A34A);
      dot   = const Color(0xFF22C55E);
      label = 'Publicado';
    }

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: text)),
        ],
      ),
    );
  }
}

// ── Tab navigation ─────────────────────────────────────────────────────────────
class _TabNav extends StatelessWidget {
  const _TabNav({
    required this.tabs,
    required this.activeTab,
    required this.hasDraft,
    required this.onSelect,
  });

  final List<(String id, String label, bool ownerOnly)> tabs;
  final String   activeTab;
  final bool     hasDraft;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: tabs.map((t) {
                final active  = t.$1 == activeTab;
                final isDraft = t.$1 == 'publish' && hasDraft;

                return GestureDetector(
                  onTap: () => onSelect(t.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: active ? AppColors.kBlue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          t.$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? AppColors.kBlue
                                : const Color(0xFF64748B),
                          ),
                        ),
                        if (isDraft) ...[
                          const SizedBox(width: 5),
                          Container(
                            width: 7, height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contenido de cada tab ─────────────────────────────────────────────────────
class _TabContent extends StatelessWidget {
  const _TabContent({
    super.key,
    required this.tab,
    required this.menu,
    required this.isOwner,
    required this.saving,
    required this.publishing,
    required this.onSave,
    required this.onPublish,
    required this.onUnpublish,
    required this.onGoToCategories,
    required this.onTransferido,
  });

  final String   tab;
  final EditorMenu menu;
  final bool     isOwner;
  final bool     saving;
  final bool     publishing;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final Future<void> Function() onPublish;
  final Future<void> Function() onUnpublish;
  final VoidCallback onGoToCategories;
  final VoidCallback onTransferido;

  @override
  Widget build(BuildContext context) {
    final draft = menu.draft;

    switch (tab) {
      case 'categories':
        return CategoriesTab(
          draft:        draft,
          onSave:       onSave,
          saving:       saving,
          subscription: menu.subscription,
        );

      case 'products':
        return ProductsTab(
          draft:            draft,
          onSave:           onSave,
          saving:           saving,
          menuId:           menu.id,
          subscription:     menu.subscription,
          onGoToCategories: onGoToCategories,
        );

      case 'grupos':
        return GruposTab(
          draft:  draft,
          onSave: onSave,
          saving: saving,
        );

      case 'design':
        return DesignTab(
          draft:  draft,
          menuId: menu.id,
          onSave: onSave,
          saving: saving,
        );

      case 'publish':
        if (!isOwner) return const SizedBox();
        return PublishTab(
          menu:        menu,
          onPublish:   onPublish,
          onUnpublish: onUnpublish,
          publishing:  publishing,
        );

      case 'colaboradores':
        if (!isOwner) return const SizedBox();
        return ColaboradoresTab(
          menuId:       menu.id,
          subscription: menu.subscription,
          transferible: menu.transferible,
          onTransferido: onTransferido,
        );

      default:
        return const SizedBox();
    }
  }
}
