import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../components/menu_page.dart';
import '../../../../shared/app_colors.dart';
import '../hooks/use_public_menu.dart';

// Equivalente a src/pages/PublicMenuPage.jsx en React

class PublicMenuPage extends StatelessWidget {
  const PublicMenuPage({
    super.key,
    required this.slug,
    this.staffMode = false,
    this.initialProductId,
  });

  final String slug;
  final bool staffMode;
  final String? initialProductId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UsePublicMenu()..load(slug: slug, staffMode: staffMode),
      child: _PublicMenuView(
        slug: slug,
        staffMode: staffMode,
        initialProductId: initialProductId,
      ),
    );
  }
}

class _PublicMenuView extends StatelessWidget {
  const _PublicMenuView({
    required this.slug,
    required this.staffMode,
    this.initialProductId,
  });

  final String slug;
  final bool staffMode;
  final String? initialProductId;

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
        ),
      ),
    );
  }
}
