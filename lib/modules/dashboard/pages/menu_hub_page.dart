import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../components/layout/sidebar.dart';
import '../../../services/mis_menus_service.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/app_header.dart';
import '../components/delete_menu_modal.dart';
import '../components/menu_steps.dart';
import '../models/dashboard_models.dart';

// Equivalente a src/modules/dashboard/pages/MenuHubPage.jsx en React.
// Las acciones de edición que dependen de fases futuras se muestran
// deshabilitadas para no llevar a pantallas incompletas.

class MenuHubPage extends StatefulWidget {
  const MenuHubPage({super.key, required this.codigo});

  final String codigo;

  @override
  State<MenuHubPage> createState() => _MenuHubPageState();
}

class _MenuHubPageState extends State<MenuHubPage> {
  MenuResumen? _menu;
  bool _loading = true;
  String? _error;
  bool _deletingCode = false;
  bool _unpublishing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final menu = await MisMenusService.getResumen(widget.codigo);
      if (!mounted) return;
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

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _share() async {
    final menu = _menu;
    if (menu == null) return;
    final url = 'https://app.zammpy.com/menu/${menu.slug}';
    await Share.share(url, subject: 'Menú digital de ${menu.nombre}');
  }

  Future<void> _unpublish() async {
    final menu = _menu;
    if (menu == null || _unpublishing) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Despublicar menú'),
        content: Text(
          'El menú "${menu.nombre}" dejará de ser visible para los clientes. '
          'Podrás volver a publicarlo después.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Despublicar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _unpublishing = true);
    try {
      await MisMenusService.unpublish(menu.codigo);
      MisMenusService.invalidate();
      if (!mounted) return;
      _snack('Menú despublicado.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _unpublishing = false);
    }
  }

  Future<void> _delete() async {
    final menu = _menu;
    if (menu == null || _deletingCode) return;

    setState(() => _deletingCode = true);
    String code;
    try {
      code = await MisMenusService.getDeleteCode(menu.codigo);
      if (code.isEmpty) throw Exception('Código de confirmación vacío.');
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
      setState(() => _deletingCode = false);
      return;
    }
    if (!mounted) return;
    setState(() => _deletingCode = false);

    final deleted = await DeleteMenuModal.show(
      context,
      menuName: menu.nombre.isNotEmpty ? menu.nombre : menu.slug,
      confirmWord: code,
      onDelete: (value) => MisMenusService.deleteMenu(menu.codigo, value),
    );
    if (deleted == true && mounted) {
      MisMenusService.invalidate();
      context.go('/menus');
    }
  }

  void _futureAction(String label, String fase) {
    _snack('$label estará disponible en la Fase $fase.');
  }

  // Igual que PasosMenu.jsx: casi todo se completa en el propio menú (/menu/:slug?editar=<sección que se abre al
  // llegar>); el horario, en la información del menú.
  static const _editarPorPaso = {
    'imagenes': 'portada',
    'ubicacion': 'informacion',
    'contacto': 'informacion',
    'productos': 'producto-nuevo',
    'redes': 'informacion',
    'galeria': 'informacion',
  };

  void _openStep(PasoMenu paso) {
    final menu = _menu;
    if (menu == null) return;
    if (paso.codigo == 'horario') {
      context.push('/menus/${menu.codigo}/info?paso=horario');
      return;
    }
    final editar = _editarPorPaso[paso.codigo];
    context.push('/menu/${menu.slug}${editar == null ? '' : '?editar=$editar'}');
  }

  @override
  Widget build(BuildContext context) {
    final menu = _menu;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) {
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
        } else {
          context.go('/menus');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.kBgPage,
        drawer: const AppSidebar(),
        appBar: AppHeader(
          title: menu?.nombre.isNotEmpty == true ? menu!.nombre : 'Menú',
          subtitle: menu == null ? null : '/menu/${menu.slug}',
        ),
        body: _buildBody(menu),
      ),
    );
  }

  Widget _buildBody(MenuResumen? menu) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.kBlue),
      );
    }
    if (_error != null || menu == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 36,
                color: AppColors.kTextMuted,
              ),
              const SizedBox(height: 10),
              const Text(
                'No se pudo cargar el menú',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextPrimary,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.kTextMuted,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text('Reintentar'),
              ),
              TextButton(
                onPressed: () => context.go('/menus'),
                child: const Text('Volver a Mis Menús'),
              ),
            ],
          ),
        ),
      );
    }

    final actions = _actions(menu);
    return RefreshIndicator(
      color: AppColors.kBlue,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        children: [
          Row(
            children: [
              _StatusBadge(publicado: menu.publicado),
              if (menu.miRol != null) ...[
                const SizedBox(width: 6),
                _RoleBadge(role: menu.miRol!),
              ],
            ],
          ),
          if (menu.puedeGestionar) ...[
            const SizedBox(height: 16),
            MenuSteps(pasos: menu.pasos, onTap: _openStep),
          ],
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 165,
              mainAxisExtent: 108,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) =>
                _ActionTile(action: actions[index]),
          ),
          const SizedBox(height: 18),
          if (menu.esPropio && menu.publicado)
            OutlinedButton.icon(
              onPressed: _unpublishing ? null : _unpublish,
              icon: _unpublishing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : const Icon(Icons.visibility_off_outlined, size: 16),
              label: Text(
                _unpublishing ? 'Despublicando…' : 'Despublicar menú',
              ),
            ),
          if (menu.esPropio) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _deletingCode ? null : _delete,
              icon: _deletingCode
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : const Icon(Icons.delete_outline, size: 16),
              label: Text(_deletingCode ? 'Preparando…' : 'Eliminar menú'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.kRed,
                side: const BorderSide(color: Color(0xFFFECACA)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_HubAction> _actions(MenuResumen menu) {
    final actions = <_HubAction>[];
    final verPublico = _HubAction(
      icon: Icons.open_in_new,
      label: 'Ver menú',
      onTap: () => context.push('/menu/${menu.slug}'),
    );

    if (menu.esMesero) {
      actions.add(
        _HubAction(
          icon: Icons.restaurant_outlined,
          label: 'Vista mesero',
          onTap: () => context.push('/menu/${menu.slug}?staff=1'),
        ),
      );
      actions.add(verPublico);
      return actions;
    }

    if (menu.esRepartidor) {
      actions.add(verPublico);
      return actions;
    }

    if (menu.puedeGestionar) {
      actions.add(
        _HubAction(
          icon: Icons.edit_outlined,
          label: 'Editar menú',
          // se edita en el propio menú, como un perfil (igual que React)
          onTap: () => context.push('/menu/${menu.slug}'),
        ),
      );
      actions.add(
        _HubAction(
          icon: Icons.layers_outlined,
          label: 'Grupos de opciones',
          onTap: () => context.push('/menus/${menu.codigo}/edit?tab=groups'),
        ),
      );
      actions.add(
        _HubAction(
          icon: Icons.bar_chart_outlined,
          label: 'Estadísticas',
          onTap: () => context.push('/menus/${menu.codigo}/estadisticas'),
        ),
      );
      actions.add(
        _HubAction(
          icon: Icons.receipt_long_outlined,
          label: 'Pedidos',
          onTap: () => _futureAction('Los pedidos', '14'),
        ),
      );
      actions.add(
        _HubAction(
          icon: Icons.table_restaurant_outlined,
          label: 'Mesas',
          onTap: () => _futureAction('Las mesas', '15'),
        ),
      );
      actions.add(
        _HubAction(
          icon: Icons.upload_outlined,
          label: 'Plan y visibilidad',
          onTap: () => context.push('/menus/${menu.codigo}/edit?tab=publish'),
        ),
      );
      if (menu.esPropio) {
        actions.add(
          _HubAction(
            icon: Icons.people_outline,
            label: 'Colaboradores',
            onTap: () =>
                context.push('/menus/${menu.codigo}/edit?tab=collaborators'),
          ),
        );
      }
    }

    actions.add(verPublico);
    actions.add(
      _HubAction(icon: Icons.share_outlined, label: 'Compartir', onTap: _share),
    );
    return actions;
  }
}

class _HubAction {
  const _HubAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final _HubAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.kCardBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 23, color: AppColors.kTextSecondary),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextSecondary,
                    height: 1.25,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.publicado});

  final bool publicado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: publicado ? AppColors.kBlue : const Color(0xFF64748B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        publicado ? 'Publicado' : 'No publicado',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      'mesero' => 'Mesero',
      'repartidor' => 'Repartidor',
      'editor' => 'Editor',
      _ => role,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.kBlue,
        ),
      ),
    );
  }
}
