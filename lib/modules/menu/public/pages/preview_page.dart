import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../components/menu_page.dart';
import '../../../../shared/app_colors.dart';
import '../hooks/use_public_menu.dart';

// Equivalente a src/modules/menu/public/pages/PreviewPage.jsx en React
// Muestra el borrador del menÃº con una barra de "Vista previa" arriba.
// Por ahora solo lectura â€” publicar/guardar tema se implementa despuÃ©s.

class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key, required this.menuId});
  final String menuId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UsePublicMenu()..load(previewId: menuId),
      child: _PreviewView(menuId: menuId),
    );
  }
}

class _PreviewView extends StatelessWidget {
  const _PreviewView({required this.menuId});
  final String menuId;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UsePublicMenu>();

    if (ctrl.loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: AppColors.kBlue)),
      );
    }

    if (ctrl.notFound || ctrl.menuData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'MenÃº no encontrado.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Volver',
                  style: TextStyle(color: AppColors.kBlue),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ctrl.menuData!.theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // â”€â”€ Barra de preview â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _PreviewBar(menuId: menuId),
            // â”€â”€ MenÃº (borrador) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: MenuPage(
                menuData: ctrl.menuData!,
                menuSlug: ctrl.menuData!.slug.isEmpty
                    ? null
                    : ctrl.menuData!.slug,
                menuCodigo: ctrl.menuData!.menuId,
                showQrButton: true,
                isPublished: false,
                esPropio: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBar extends StatelessWidget {
  const _PreviewBar({required this.menuId});
  final String menuId;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.visibility_outlined,
            size: 14,
            color: Color(0xFFFBBF24),
          ),
          const SizedBox(width: 6),
          const Text(
            'Vista previa',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'â€” Borrador Â· no publicado aÃºn',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
