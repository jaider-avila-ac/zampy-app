import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../hooks/use_public_menu.dart';
import '../components/share_modal.dart';
import '../../../../components/menu_page.dart';
import '../../../../shared/app_colors.dart';

// Equivalente a src/pages/PublicMenuPage.jsx en React
// Página de ruta /menu/:slug — carga y renderiza un menú público

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
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: AppColors.kTextPrimary),
        ),
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

    final theme = ctrl.menuData!.theme;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Toolbar: back + QR/share (equivalente a Navbar con onQr en React)
            Container(
              height: 48,
              color:  theme.surface,
              child: Row(
                children: [
                  IconButton(
                    icon:      const Icon(Icons.arrow_back_ios_new, size: 18),
                    onPressed: () => Navigator.of(context).maybePop(),
                    color:     theme.text,
                  ),
                  const Spacer(),
                  // Botón QR (equivalente al botón QrCode en Navbar de React)
                  IconButton(
                    icon:      const Icon(Icons.qr_code, size: 20),
                    onPressed: () => ShareModal.show(context, slug, theme),
                    color:     theme.text,
                    tooltip:   'Compartir / QR',
                  ),
                ],
              ),
            ),
            Expanded(
              child: MenuPage(
                menuData:    ctrl.menuData!,
                menuSlug:    slug,
                isPublished: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
