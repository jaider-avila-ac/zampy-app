import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/layout/sidebar.dart';
import '../../../../services/live_editor_service.dart';
import '../../../../shared/app_colors.dart';
import '../../../../shared/app_header.dart';
import 'editor_models.dart';
import 'tabs/collaborators_live_tab.dart';
import 'tabs/groups_live_tab.dart';
import 'tabs/publish_live_tab.dart';

// Lo que queda del editor por pestañas (como en React): grupos de opciones, plan y visibilidad, y colaboradores.
// Las categorías, los productos, el diseño y la información se editan en el propio menú (/menu/:slug, ver
// modules/menu/public/edicion); la información completa y el horario también en /menus/:codigo/info. Cualquier
// otra pestaña lleva al propio menú.

class LiveMenuEditorPage extends StatefulWidget {
  const LiveMenuEditorPage({super.key, required this.codigo, this.initialTab});

  final String codigo;
  final String? initialTab;

  @override
  State<LiveMenuEditorPage> createState() => _LiveMenuEditorPageState();
}

class _LiveMenuEditorPageState extends State<LiveMenuEditorPage> {
  LiveMenu? _menu;
  bool _loading = true;
  String? _error;
  String _tab = 'groups';

  static const _tabs = [
    ('groups', 'Grupos'),
    ('publish', 'Plan y visibilidad'),
    ('collaborators', 'Colaboradores'),
  ];

  bool get _tabDelEditor => _tabs.any((t) => t.$1 == widget.initialTab);

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) _tab = widget.initialTab!;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final menu = await LiveEditorService.load(widget.codigo);
      if (!mounted) return;
      if (menu.esMesero || menu.esRepartidor) {
        context.replace('/${menu.slug}?staff=1');
        return;
      }
      // sin pestaña (o una que ya se edita en el menú): al propio menú, como RedirigirMiMenu de React
      if (!_tabDelEditor) {
        context.replace('/${menu.slug}');
        return;
      }
      setState(() {
        _menu = menu;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.kRed : AppColors.kBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    final menu = _menu;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) {
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
        } else {
          context.go('/menus/${widget.codigo}');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.kBgPage,
        drawer: const AppSidebar(),
        appBar: AppHeader(
          title: menu?.info.name.isNotEmpty == true
              ? menu!.info.name
              : 'Editor del menú',
          subtitle: menu == null ? null : '/${menu.slug}',
          actions: [
            // Una sola acción, como el EditorHeader de React: abrir el menú para editarlo (/<slug>).
            if (menu != null)
              IconButton(
                tooltip: 'Editar menú',
                onPressed: () => context.push('/${menu.slug}'),
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
          ],
        ),
        body: _buildBody(menu),
      ),
    );
  }

  Widget _buildBody(LiveMenu? menu) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.kBlue),
      );
    }
    if (_error != null || menu == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: AppColors.kTextMuted,
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? 'No se pudo cargar el menú.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 15),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final tabs = _tabs
        .where((t) => t.$1 != 'collaborators' || menu.esPropio)
        .toList();
    final active = tabs.any((t) => t.$1 == _tab) ? _tab : 'groups';

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: tabs.map((t) {
                final selected = t.$1 == active;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(t.$2),
                    selected: selected,
                    onSelected: (_) => setState(() => _tab = t.$1),
                    selectedColor: const Color(0xFFEEF2FF),
                    side: BorderSide(
                      color: selected ? AppColors.kBlue : AppColors.kCardBorder,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.kBlue
                          : AppColors.kTextSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(child: _tabContent(active, menu)),
      ],
    );
  }

  Widget _tabContent(String tab, LiveMenu menu) {
    switch (tab) {
      case 'groups':
        return GroupsLiveTab(menu: menu, onChanged: _refresh);
      case 'publish':
        return PublishLiveTab(menu: menu, onChanged: _refresh, onSnack: _snack);
      case 'collaborators':
        return CollaboratorsLiveTab(
          menu: menu,
          onSnack: _snack,
          onTransferido: () => context.go('/menus'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
