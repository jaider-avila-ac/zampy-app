import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../hooks/use_public_menu.dart';
import '../../../../components/menu_page.dart';
import '../../../../shared/app_colors.dart';

// Equivalente a src/pages/PublicMenuPage.jsx en React
// Carga el menú y delega el render completo (Navbar incluido) a MenuPage

class PublicMenuPage extends StatelessWidget {
  const PublicMenuPage({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UsePublicMenu()..load(slug: slug),
      child: _PublicMenuView(slug: slug),
    );
  }
}

class _PublicMenuView extends StatelessWidget {
  const _PublicMenuView({required this.slug});
  final String slug;

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
              Icon(Icons.error_outline, size: 48, color: AppColors.kTextMuted),
              const SizedBox(height: 12),
              Text(
                'No se encontró el menú',
                style: TextStyle(fontSize: 14, color: AppColors.kTextMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.read<UsePublicMenu>().load(slug: slug),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ctrl.menuData!.theme.bg,
      body: SafeArea(
        child: MenuPage(
          menuData:    ctrl.menuData!,
          menuSlug:    slug,
          isPublished: true,
        ),
      ),
    );
  }
}
