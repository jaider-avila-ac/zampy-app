import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../components/menu_page.dart';
import '../../../../shared/app_colors.dart';
import '../edicion/menu_editable.dart';
import '../../../mesero/utils/tomar_orden.dart';
import '../hooks/use_public_menu.dart';

// Equivalente a src/pages/PublicMenuPage.jsx en React

class PublicMenuPage extends StatelessWidget {
  const PublicMenuPage({
    super.key,
    required this.slug,
    this.staffMode = false,
    this.initialProductId,
    this.editar,
    this.mesero,
  });

  final String slug;
  final bool staffMode;

  /// `?mesa=…`: el mesero arma la orden de esa mesa (ve el menú como el cliente, sin edición ni carrito).
  final DestinoOrden? mesero;

  bool get _personal => staffMode || mesero != null;
  final String? initialProductId;

  /// `?editar=sección`: abre esa sección de la edición al llegar (si quien entra puede editar el menú).
  final String? editar;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UsePublicMenu()..load(slug: slug, staffMode: _personal),
      child: _PublicMenuView(
        slug: slug,
        staffMode: _personal,
        mesero: mesero,
        initialProductId: initialProductId,
        editar: editar,
      ),
    );
  }
}

class _PublicMenuView extends StatelessWidget {
  const _PublicMenuView({
    required this.slug,
    required this.staffMode,
    this.initialProductId,
    this.editar,
    this.mesero,
  });

  final String slug;
  final bool staffMode;
  final String? initialProductId;
  final String? editar;
  final DestinoOrden? mesero;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UsePublicMenu>();

    if (ctrl.loading) {
      return const Scaffold(
        backgroundColor: AppColors.kBgPage,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (ctrl.notFound || ctrl.menuData == null) {
      return Scaffold(
        backgroundColor: AppColors.kBgPage,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.kTextMuted,
              ),
              const SizedBox(height: 12),
              const Text(
                'Este menú no está disponible o no ha sido publicado.',
                style: TextStyle(fontSize: 14, color: AppColors.kTextMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.read<UsePublicMenu>().load(
                  slug: slug,
                  staffMode: staffMode,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final menu = ctrl.menuData!;

    // Como un perfil: el dueño o un editor (lo dice el backend con GET /menus/acceso) lo edita aquí mismo; ve el menú
    // igual que el cliente, con las opciones de edición. El personal (mesero, repartidor) y los demás lo ven normal.
    final codigo = ctrl.acceso?['codigo']?.toString();
    if (ctrl.editando && codigo != null) {
      return Scaffold(
        backgroundColor: menu.theme.bg,
        body: SafeArea(
          child: MenuEditable(
            menuData: menu,
            menuCodigo: codigo,
            publicado: ctrl.publicado,
            esPropio: ctrl.esPropietario,
            recargar: ctrl.recargar,
            onEstado: ctrl.recargarAcceso,
            seccionInicial: editar,
            initialProductId: initialProductId,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: menu.theme.bg,
      body: SafeArea(
        child: MenuPage(
          menuData: menu,
          menuSlug: slug,
          menuCodigo: menu.menuId,
          isPublished: menu.publicado,
          staffMode: staffMode,
          esPropio: menu.esPropio || ctrl.esEditor,
          initialProductId: initialProductId,
          mesero: mesero,
        ),
      ),
    );
  }
}
